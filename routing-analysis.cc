/*  routing-analysis.cc
 *  MANET routing comparison - FIXED VERSION
 *  Compatible with ns-3.40
 */

#include "ns3/aodv-module.h"
#include "ns3/applications-module.h"
#include "ns3/core-module.h"
#include "ns3/dsdv-module.h"
#include "ns3/dsr-module.h"
#include "ns3/internet-module.h"
#include "ns3/mobility-module.h"
#include "ns3/network-module.h"
#include "ns3/olsr-module.h"
#include "ns3/yans-wifi-helper.h"
#include "ns3/wifi-module.h"
#include "ns3/netanim-module.h"

#include <fstream>
#include <iostream>
#include <iomanip>
#include <map>

using namespace ns3;
using namespace dsr;

NS_LOG_COMPONENT_DEFINE("RoutingAnalysis");

class MyTimestampTag : public Tag
{
public:
  Time m_timestamp;

  static TypeId GetTypeId()
  {
    static TypeId tid = TypeId("MyTimestampTag")
                            .SetParent<Tag>()
                            .AddConstructor<MyTimestampTag>();
    return tid;
  }

  virtual TypeId GetInstanceTypeId() const override { return GetTypeId(); }
  virtual uint32_t GetSerializedSize() const override { return 8; }
  
  virtual void Serialize(TagBuffer i) const override
  {
    i.WriteDouble(m_timestamp.GetSeconds());
  }

  virtual void Deserialize(TagBuffer i) override
  {
    m_timestamp = Seconds(i.ReadDouble());
  }

  virtual void Print(std::ostream& os) const override
  {
    os << "Timestamp=" << m_timestamp.GetSeconds();
  }

  void SetTimestamp(Time time) { m_timestamp = time; }
  Time GetTimestamp() const { return m_timestamp; }
};

class RoutingExperiment
{
public:
  RoutingExperiment();
  ~RoutingExperiment();
  void Run();
  void CommandSetup(int argc, char** argv);

private:
  void SetupTraffic();
  void ReceivePacket(Ptr<Socket> socket);
  void SendPacket(Ptr<Socket> socket, uint32_t pktSize, uint32_t numPkts, Time interval);
  void CheckThroughput();
  void MacTxCallback(Ptr<const Packet> packet);
  void PrintFinalStatistics();

  uint32_t m_port;
  uint32_t m_bytesTotal;
  uint32_t m_packetsReceived;
  uint32_t m_packetsSent;
  double m_totalDelay;
  uint32_t m_delaySamples;
  uint32_t m_routingPackets;
  double m_minDelay;
  double m_maxDelay;
  uint32_t m_packetsDropped;

  std::string m_CSVfileName;
  int m_nSinks;
  std::string m_protocolName;
  double m_txp;
  int m_nWifis;
  double m_totalTime;
  std::string m_rate;
  double m_nodeSpeed;
  double m_pauseTime;

  NodeContainer m_nodes;
  Ipv4InterfaceContainer m_interfaces;
  std::map<Ptr<Socket>, EventId> m_socketEvents;
  std::vector<Ptr<Socket>> m_sockets;
};

RoutingExperiment::RoutingExperiment()
    : m_port(9),
      m_bytesTotal(0),
      m_packetsReceived(0),
      m_packetsSent(0),
      m_totalDelay(0.0),
      m_delaySamples(0),
      m_routingPackets(0),
      m_minDelay(std::numeric_limits<double>::max()),
      m_maxDelay(0.0),
      m_packetsDropped(0),
      m_CSVfileName("routing-analysis.csv"),
      m_nSinks(5),
      m_protocolName("AODV"),
      m_txp(25.0),
      m_nWifis(25),
      m_totalTime(200.0),
      m_rate("2048bps"),
      m_nodeSpeed(2.0),
      m_pauseTime(5.0)
{
}

RoutingExperiment::~RoutingExperiment()
{
  for (auto& pair : m_socketEvents)
  {
    if (pair.second.IsRunning())
    {
      Simulator::Cancel(pair.second);
    }
  }
  
  for (auto& socket : m_sockets)
  {
    if (socket)
    {
      socket->Close();
    }
  }
}

void RoutingExperiment::ReceivePacket(Ptr<Socket> socket)
{
  Ptr<Packet> packet;
  Address from;

  while ((packet = socket->RecvFrom(from)))
  {
    if (packet->GetSize() > 0)
    {
      m_bytesTotal += packet->GetSize();
      m_packetsReceived++;

      MyTimestampTag tag;
      if (packet->PeekPacketTag(tag))
      {
        Time delay = Simulator::Now() - tag.GetTimestamp();
        double delaySeconds = delay.GetSeconds();
        
        m_totalDelay += delaySeconds;
        m_delaySamples++;
        
        if (delaySeconds < m_minDelay)
          m_minDelay = delaySeconds;
        if (delaySeconds > m_maxDelay)
          m_maxDelay = delaySeconds;
      }
    }
  }
}

void RoutingExperiment::SendPacket(Ptr<Socket> socket, uint32_t pktSize, uint32_t numPkts, Time interval)
{
  if (numPkts > 0 && Simulator::Now().GetSeconds() < m_totalTime - 1.0)
  {
    Ptr<Packet> packet = Create<Packet>(pktSize);

    MyTimestampTag tag;
    tag.SetTimestamp(Simulator::Now());
    packet->AddPacketTag(tag);

    int bytesSent = socket->Send(packet);
    if (bytesSent > 0)
    {
      m_packetsSent++;
    }
    else
    {
      m_packetsDropped++;
    }

    m_socketEvents[socket] = Simulator::Schedule(interval, 
                                                  &RoutingExperiment::SendPacket, 
                                                  this, 
                                                  socket, 
                                                  pktSize, 
                                                  numPkts - 1, 
                                                  interval);
  }
}

void RoutingExperiment::CheckThroughput()
{
  double kbs = (m_bytesTotal * 8.0) / 1000.0;
  m_bytesTotal = 0;

  double pdr = (m_packetsSent == 0) ? 0.0 : (double)m_packetsReceived / m_packetsSent;
  double avgDelay = (m_delaySamples == 0) ? 0.0 : m_totalDelay / m_delaySamples;

  std::ofstream out(m_CSVfileName, std::ios::app);
  out << std::fixed << std::setprecision(4)
      << Simulator::Now().GetSeconds() << ","
      << kbs << ","
      << m_packetsReceived << ","
      << m_nSinks << ","
      << m_protocolName << ","
      << m_txp << ","
      << pdr << ","
      << avgDelay << ","
      << m_routingPackets << std::endl;
  out.close();

 // m_packetsReceived = 0;
  
  if (Simulator::Now().GetSeconds() < m_totalTime - 1.0)
  {
    Simulator::Schedule(Seconds(1.0), &RoutingExperiment::CheckThroughput, this);
  }
}

void RoutingExperiment::MacTxCallback(Ptr<const Packet> packet)
{
  if (packet->GetSize() < 200)
  {
    m_routingPackets++;
  }
}

void RoutingExperiment::SetupTraffic()
{
  DataRate dataRate(m_rate);
  uint32_t packetSize = 64;
  double packetsPerSecond = dataRate.GetBitRate() / (packetSize * 8.0);
  Time interPacketInterval = Seconds(1.0 / packetsPerSecond);

  // FIXED: Start traffic at 30 seconds (was 100-101)
  Ptr<UniformRandomVariable> startTimeRng = CreateObject<UniformRandomVariable>();
  startTimeRng->SetAttribute("Min", DoubleValue(30.0));
  startTimeRng->SetAttribute("Max", DoubleValue(31.0));

  std::cout << "Setting up " << m_nSinks << " traffic flows..." << std::endl;
  std::cout << "Packet size: " << packetSize << " bytes" << std::endl;
  std::cout << "Data rate: " << m_rate << " (" << packetsPerSecond << " pkt/s)" << std::endl;

  for (int i = 0; i < m_nSinks; i++)
  {
    TypeId tid = TypeId::LookupByName("ns3::UdpSocketFactory");
    Ptr<Socket> recvSink = Socket::CreateSocket(m_nodes.Get(i), tid);
    InetSocketAddress local = InetSocketAddress(m_interfaces.GetAddress(i), m_port);
    recvSink->Bind(local);
    recvSink->SetRecvCallback(MakeCallback(&RoutingExperiment::ReceivePacket, this));
    m_sockets.push_back(recvSink);

    Ptr<Socket> source = Socket::CreateSocket(m_nodes.Get(i + m_nSinks), tid);
    InetSocketAddress remote = InetSocketAddress(m_interfaces.GetAddress(i), m_port);
    source->Connect(remote);
    m_sockets.push_back(source);

    // FIXED: Calculate packets correctly
    uint32_t numPackets = static_cast<uint32_t>((m_totalTime - 30.0) * packetsPerSecond);
    Time startTime = Seconds(startTimeRng->GetValue());

    std::cout << "Flow " << i << ": Node " << (i + m_nSinks) 
              << " -> Node " << i 
              << " (" << numPackets << " packets)" << std::endl;

    Simulator::Schedule(startTime, 
                       &RoutingExperiment::SendPacket, 
                       this, 
                       source, 
                       packetSize, 
                       numPackets, 
                       interPacketInterval);
  }
}

void RoutingExperiment::CommandSetup(int argc, char** argv)
{
  CommandLine cmd(__FILE__);
  cmd.AddValue("protocol", "Routing protocol (AODV, OLSR, DSDV, DSR)", m_protocolName);
  cmd.AddValue("CSVfileName", "Output CSV filename", m_CSVfileName);
  cmd.AddValue("nSinks", "Number of sink nodes", m_nSinks);
  cmd.AddValue("txp", "Transmission power (dBm)", m_txp);
  cmd.AddValue("nWifis", "Number of WiFi nodes", m_nWifis);
  cmd.AddValue("totalTime", "Total simulation time (seconds)", m_totalTime);
  cmd.AddValue("rate", "Data rate (e.g., 2048bps)", m_rate);
  cmd.AddValue("nodeSpeed", "Maximum node speed (m/s)", m_nodeSpeed);
  cmd.AddValue("pauseTime", "Pause time at waypoints (s)", m_pauseTime);
  cmd.Parse(argc, argv);

  if (m_nSinks * 2 > m_nWifis)
  {
    std::cerr << "Error: nSinks * 2 must be <= nWifis" << std::endl;
    std::exit(1);
  }
}

void RoutingExperiment::PrintFinalStatistics()
{
  std::cout << "\n========================================" << std::endl;
  std::cout << "FINAL STATISTICS - " << m_protocolName << std::endl;
  std::cout << "========================================" << std::endl;
  std::cout << "Total packets sent: " << m_packetsSent << std::endl;
  std::cout << "Total packets received: " << m_packetsReceived << std::endl;
  std::cout << "Packets dropped: " << m_packetsDropped << std::endl;
  
  double finalPDR = (m_packetsSent == 0) ? 0.0 : (double)m_packetsReceived / m_packetsSent;
  std::cout << "Overall PDR: " << std::fixed << std::setprecision(4) 
            << (finalPDR * 100.0) << "%" << std::endl;
  
  double avgDelay = (m_delaySamples == 0) ? 0.0 : m_totalDelay / m_delaySamples;
  std::cout << "Average delay: " << avgDelay << " seconds" << std::endl;
  std::cout << "Min delay: " << m_minDelay << " seconds" << std::endl;
  std::cout << "Max delay: " << m_maxDelay << " seconds" << std::endl;
  std::cout << "Total routing packets: " << m_routingPackets << std::endl;
  std::cout << "========================================\n" << std::endl;
}

void RoutingExperiment::Run()
{
  m_CSVfileName = m_protocolName + "-OUTPUT.csv";

  std::ofstream out(m_CSVfileName);
  out << "Time,ThroughputKbps,PacketsReceived,Sinks,Protocol,TxPower,PDR,AvgDelay,RoutingOverhead\n";
  out.close();

  std::cout << "\n========================================" << std::endl;
  std::cout << "MANET Routing Protocol Comparison" << std::endl;
  std::cout << "========================================" << std::endl;
  std::cout << "Protocol: " << m_protocolName << std::endl;
  std::cout << "Number of nodes: " << m_nWifis << std::endl;
  std::cout << "Number of flows: " << m_nSinks << std::endl;
  std::cout << "Simulation time: " << m_totalTime << " seconds" << std::endl;
  std::cout << "Node speed: 1-" << m_nodeSpeed << " m/s" << std::endl;
  std::cout << "Tx power: " << m_txp << " dBm" << std::endl;
  std::cout << "========================================\n" << std::endl;

  m_nodes.Create(m_nWifis);
  std::cout << "Created " << m_nWifis << " nodes" << std::endl;

  // WiFi configuration - FIXED
  WifiHelper wifi;
  wifi.SetStandard(WIFI_STANDARD_80211b);
  wifi.SetRemoteStationManager("ns3::ConstantRateWifiManager",
                               "DataMode", StringValue("DsssRate11Mbps"),
                               "ControlMode", StringValue("DsssRate1Mbps"));

  YansWifiPhyHelper wifiPhy;
  YansWifiChannelHelper wifiChannel = YansWifiChannelHelper::Default();
  wifiPhy.SetChannel(wifiChannel.Create());

  // FIXED: Use the parameter value for tx power
  wifiPhy.Set("TxPowerStart", DoubleValue(m_txp));
  wifiPhy.Set("TxPowerEnd", DoubleValue(m_txp));

  WifiMacHelper wifiMac;
  wifiMac.SetType("ns3::AdhocWifiMac");

  NetDeviceContainer devices = wifi.Install(wifiPhy, wifiMac, m_nodes);
  std::cout << "WiFi devices installed" << std::endl;

  Config::ConnectWithoutContext("/NodeList/*/DeviceList/*/Mac/MacTx",
                                MakeCallback(&RoutingExperiment::MacTxCallback, this));

  // Mobility model - FIXED: Smaller area (200x200 instead of 300x300)
  MobilityHelper mobility;
  ObjectFactory posFactory;
  posFactory.SetTypeId("ns3::RandomRectanglePositionAllocator");
  posFactory.Set("X", StringValue("ns3::UniformRandomVariable[Min=0.0|Max=200.0]"));
  posFactory.Set("Y", StringValue("ns3::UniformRandomVariable[Min=0.0|Max=200.0]"));

  Ptr<PositionAllocator> positionAlloc = posFactory.Create()->GetObject<PositionAllocator>();
  
  std::stringstream speedStream;
  speedStream << "ns3::UniformRandomVariable[Min=1.0|Max=" << m_nodeSpeed << "]";
  
  std::stringstream pauseStream;
  pauseStream << "ns3::ConstantRandomVariable[Constant=" << m_pauseTime << "]";
  
  mobility.SetMobilityModel("ns3::RandomWaypointMobilityModel",
                            "Speed", StringValue(speedStream.str()),
                            "Pause", StringValue(pauseStream.str()),
                            "PositionAllocator", PointerValue(positionAlloc));
  mobility.SetPositionAllocator(positionAlloc);
  mobility.Install(m_nodes);
  std::cout << "Mobility model configured" << std::endl;

  AnimationInterface anim(m_protocolName + "-ANIM.xml");
  for (uint32_t i = 0; i < m_nodes.GetN(); ++i)
  {
    anim.UpdateNodeDescription(i, "N" + std::to_string(i));
    
    if (i < (uint32_t)m_nSinks)
      anim.UpdateNodeColor(i, 0, 0, 255);
    else if (i < (uint32_t)(m_nSinks * 2))
      anim.UpdateNodeColor(i, 255, 0, 0);
    else
      anim.UpdateNodeColor(i, 0, 255, 0);
  }

  InternetStackHelper internet;

  if (m_protocolName == "DSR")
  {
    std::cout << "Installing DSR routing..." << std::endl;
    internet.Install(m_nodes);
    DsrMainHelper dsrMain;
    DsrHelper dsr;
    dsrMain.Install(dsr, m_nodes);
  }
  else
  {
    Ipv4ListRoutingHelper list;

    if (m_protocolName == "AODV")
    {
      std::cout << "Installing AODV routing..." << std::endl;
      AodvHelper aodv;
      list.Add(aodv, 100);
    }
    else if (m_protocolName == "OLSR")
    {
      std::cout << "Installing OLSR routing..." << std::endl;
      OlsrHelper olsr;
      list.Add(olsr, 100);
    }
    else if (m_protocolName == "DSDV")
    {
      std::cout << "Installing DSDV routing..." << std::endl;
      DsdvHelper dsdv;
      list.Add(dsdv, 100);
    }
    else
    {
      NS_FATAL_ERROR("Unknown protocol: " << m_protocolName);
    }

    internet.SetRoutingHelper(list);
    internet.Install(m_nodes);
  }

  Ipv4AddressHelper address;
  address.SetBase("10.1.1.0", "255.255.255.0");
  m_interfaces = address.Assign(devices);
  std::cout << "IP addresses assigned" << std::endl;

  SetupTraffic();

  Simulator::Schedule(Seconds(1.0), &RoutingExperiment::CheckThroughput, this);

  std::cout << "\n>>> Starting simulation..." << std::endl;
  Simulator::Stop(Seconds(m_totalTime));
  Simulator::Run();
  
  PrintFinalStatistics();
  
  Simulator::Destroy();

  std::cout << "Results saved to: " << m_CSVfileName << std::endl;
  std::cout << "Animation saved to: " << m_protocolName << "-ANIM.xml" << std::endl;
}

int main(int argc, char* argv[])
{
  RoutingExperiment experiment;
  experiment.CommandSetup(argc, argv);
  experiment.Run();
  return 0;
}
