# MANET Routing Protocol Comparison Project

A comprehensive ns-3 simulation framework for comparing Mobile Ad-hoc Network (MANET) routing protocols including AODV, OLSR, DSR, and DSDV.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
- [Performance Metrics](#performance-metrics)
- [File Structure](#file-structure)
- [Configuration](#configuration)
- [Results Interpretation](#results-interpretation)
- [Troubleshooting](#troubleshooting)
- [Contributing](#contributing)

## 🎯 Overview

This project implements a comprehensive simulation framework to evaluate and compare the performance of four popular MANET routing protocols:

- **AODV** (Ad-hoc On-Demand Distance Vector)
- **OLSR** (Optimized Link State Routing)
- **DSR** (Dynamic Source Routing)
- **DSDV** (Destination-Sequenced Distance Vector)

The simulation analyzes protocol behavior under realistic mobile node scenarios with various network conditions.

## ✨ Features

- **Multi-Protocol Support**: Simultaneous testing of AODV, OLSR, DSR, and DSDV
- **Comprehensive Metrics**: 
  - Throughput
  - Packet Delivery Ratio (PDR)
  - End-to-End Delay
  - Routing Overhead
- **Realistic Mobility**: Random Waypoint mobility model
- **Visualization**: 
  - NetAnim support for network animation
  - Gnuplot graphs for performance comparison
  - Python matplotlib plots for advanced analysis
- **Automated Testing**: Bash script for running all protocols sequentially
- **Statistical Analysis**: Detailed statistics with min/max/average values

## 📦 Prerequisites

### Required Software

1. **ns-3** (version 3.40 or higher)
   ```bash
   # Download ns-3
   wget https://www.nsnam.org/releases/ns-allinone-3.40.tar.bz2
   tar xjf ns-allinone-3.40.tar.bz2
   cd ns-allinone-3.40/ns-3.40
   ```

2. **Build Tools**
   ```bash
   # Ubuntu/Debian
   sudo apt-get install g++ python3 cmake ninja-build git

   # Fedora/RHEL
   sudo dnf install gcc-c++ python3 cmake ninja-build git
   ```

3. **Gnuplot** (for plotting)
   ```bash
   # Ubuntu/Debian
   sudo apt-get install gnuplot

   # macOS
   brew install gnuplot
   ```

4. **Python 3** with libraries (for advanced analysis)
   ```bash
   pip3 install pandas numpy matplotlib seaborn
   ```

5. **NetAnim** (optional, for animation)
   ```bash
   # Install Qt5 first
   sudo apt-get install qt5-default

   # Build NetAnim
   cd ns-allinone-3.40/netanim-3.108
   qmake NetAnim.pro
   make
   ```

## 🚀 Installation

### Step 1: Copy Files to ns-3

```bash
# Navigate to your ns-3 installation
cd ~/ns-allinone-3.40/ns-3.40

# Copy the main simulation file
cp /path/to/routing-analysis.cc scratch/

# Copy the automation scripts
cp /path/to/run-simulation.sh .
cp /path/to/compare.gnuplot .
cp /path/to/analyze_results.py .

# Make scripts executable
chmod +x run-simulation.sh
chmod +x analyze_results.py
```

### Step 2: Build ns-3

```bash
./ns3 configure --enable-examples --enable-tests
./ns3 build
```

## 💻 Usage

### Quick Start (Automated)

Run all protocols automatically:

```bash
./run-simulation.sh
```

This will:
1. Build ns-3
2. Run simulations for AODV, OLSR, DSR, and DSDV
3. Generate CSV outputs
4. Create comparison plots
5. Generate summary statistics

### Manual Execution

Run a single protocol:

```bash
# AODV
./ns3 run "routing-analysis --protocol=AODV"

# OLSR
./ns3 run "routing-analysis --protocol=OLSR"

# DSR
./ns3 run "routing-analysis --protocol=DSR"

# DSDV
./ns3 run "routing-analysis --protocol=DSDV"
```

### Advanced Configuration

Customize simulation parameters:

```bash
./ns3 run "routing-analysis \
    --protocol=AODV \
    --nWifis=50 \
    --nSinks=10 \
    --totalTime=300 \
    --txp=20.0 \
    --rate=4096bps \
    --nodeSpeed=5.0 \
    --pauseTime=10.0"
```

### Parameters

| Parameter | Description | Default | Range |
|-----------|-------------|---------|-------|
| `protocol` | Routing protocol (AODV/OLSR/DSR/DSDV) | AODV | - |
| `nWifis` | Number of nodes | 25 | 10-100 |
| `nSinks` | Number of traffic flows | 5 | 1-20 |
| `totalTime` | Simulation duration (seconds) | 200 | 50-1000 |
| `txp` | Transmission power (dBm) | 20.0 | 10-30 |
| `rate` | Data rate | 2048bps | 512bps-10Mbps |
| `nodeSpeed` | Max node speed (m/s) | 3.0 | 0-20 |
| `pauseTime` | Pause at waypoints (s) | 5.0 | 0-60 |

## 📊 Performance Metrics

### 1. Throughput
- **Definition**: Data successfully delivered per unit time
- **Unit**: Kbps (Kilobits per second)
- **Interpretation**: Higher is better

### 2. Packet Delivery Ratio (PDR)
- **Definition**: Ratio of packets received to packets sent
- **Range**: 0 to 1 (0% to 100%)
- **Interpretation**: Higher is better (1.0 = 100% delivery)

### 3. End-to-End Delay
- **Definition**: Average time for packet to travel from source to destination
- **Unit**: Seconds
- **Interpretation**: Lower is better

### 4. Routing Overhead
- **Definition**: Number of routing control packets transmitted
- **Unit**: Packet count
- **Interpretation**: Lower is better (less network overhead)

## 📁 File Structure

```
ns-3.40/
├── scratch/
│   └── routing-analysis.cc          # Main simulation code
├── run-simulation.sh                # Automation script
├── compare.gnuplot                  # Gnuplot visualization
├── analyze_results.py               # Python analysis tool
├── results/                         # Output directory (created automatically)
│   ├── AODV-OUTPUT.csv
│   ├── OLSR-OUTPUT.csv
│   ├── DSR-OUTPUT.csv
│   ├── DSDV-OUTPUT.csv
│   ├── *-ANIM.xml                  # NetAnim files
│   └── summary-*.txt               # Statistics summary
└── plots/                          # Python-generated plots
    ├── time_series_comparison.png
    ├── average_performance.png
    └── distribution_analysis.png
```

## ⚙️ Configuration

### Modifying Network Topology

Edit the C++ code to change network size and topology:

```cpp
// In routing-analysis.cc
m_nWifis = 50;          // Number of nodes
m_nSinks = 10;          // Number of communication pairs

// Mobility area
posFactory.Set("X", StringValue("ns3::UniformRandomVariable[Min=0.0|Max=500.0]"));
posFactory.Set("Y", StringValue("ns3::UniformRandomVariable[Min=0.0|Max=500.0]"));
```

### Adjusting Traffic Patterns

Modify traffic generation parameters:

```cpp
m_rate = "4096bps";     // Data rate
uint32_t packetSize = 128;  // Packet size in bytes
```

### Changing Mobility Model

Switch between different mobility models:

```cpp
// Current: Random Waypoint
mobility.SetMobilityModel("ns3::RandomWaypointMobilityModel", ...);

// Alternative: Random Walk
mobility.SetMobilityModel("ns3::RandomWalk2dMobilityModel", ...);

// Alternative: Constant Position (static nodes)
mobility.SetMobilityModel("ns3::ConstantPositionMobilityModel");
```

## 📈 Results Interpretation

### Expected Performance Characteristics

**AODV (On-Demand)**
- ✅ Low routing overhead during low traffic
- ✅ Good scalability
- ⚠️ Higher delay during route discovery
- ⚠️ Moderate PDR under high mobility

**OLSR (Proactive)**
- ✅ Low delay (routes pre-computed)
- ✅ High PDR in stable networks
- ⚠️ High routing overhead
- ⚠️ Less efficient in highly mobile scenarios

**DSR (On-Demand)**
- ✅ No periodic routing messages
- ✅ Good for low mobility
- ⚠️ High overhead under high traffic (source routing)
- ⚠️ Scalability issues with large networks

**DSDV (Proactive)**
- ✅ Simple, table-driven
- ✅ Good for static/low mobility
- ⚠️ High overhead for route maintenance
- ⚠️ Slow convergence after topology changes

### Viewing Results

1. **CSV Files**: Raw data for each time step
2. **Gnuplot PDFs**: Time-series comparison graphs
3. **Python Plots**: Statistical analysis and distributions
4. **NetAnim XML**: Visual network simulation playback

### Analyzing with NetAnim

```bash
cd ~/ns-allinone-3.40/netanim-3.108
./NetAnim
# File > Open XML > Select *-ANIM.xml file
```

### Python Analysis

```bash
python3 analyze_results.py
```

This generates:
- Detailed statistics summary
- Box plots showing distribution
- Correlation heatmaps
- Comparative bar charts

## 🔧 Troubleshooting

### Common Issues

**1. Compilation Errors**

```bash
# Problem: Missing headers
# Solution: Ensure all ns-3 modules are enabled
./ns3 configure --enable-examples --enable-tests
./ns3 build
```

**2. Simulation Crashes**

```bash
# Problem: Segmentation fault
# Solution: Check node count vs. flows
# Ensure: nSinks * 2 <= nWifis
```

**3. Empty Output Files**

```bash
# Problem: No CSV generated
# Solution: Check file permissions and path
ls -la *.csv
# Verify simulation completed without errors
```

**4. Gnuplot Errors**

```bash
# Problem: "File not found"
# Solution: Ensure CSV files exist
ls -la *-OUTPUT.csv

# Problem: Gnuplot syntax error
# Solution: Check gnuplot version
gnuplot --version  # Should be 5.0+
```

**5. Python Import Errors**

```bash
# Problem: ModuleNotFoundError
# Solution: Install required packages
pip3 install pandas numpy matplotlib seaborn
```

### Debug Mode

Enable detailed logging:

```cpp
// In routing-analysis.cc main()
LogComponentEnable("RoutingAnalysis", LOG_LEVEL_INFO);
LogComponentEnable("AodvRoutingProtocol", LOG_LEVEL_DEBUG);
```

### Verification

Test with minimal configuration:

```bash
./ns3 run "routing-analysis \
    --protocol=AODV \
    --nWifis=10 \
    --nSinks=2 \
    --totalTime=50"
```

## 🤝 Contributing

### Code Style

- Follow ns-3 coding standards
- Use meaningful variable names
- Comment complex logic
- Keep functions focused and small

### Adding New Protocols

1. Include the protocol header
2. Add case in protocol selection
3. Configure protocol-specific parameters
4. Update documentation

Example:

```cpp
#include "ns3/batman-module.h"  // New protocol

// In Run() method
else if (m_protocolName == "BATMAN")
{
    BatmanHelper batman;
    list.Add(batman, 100);
}
```

### Reporting Issues

Include:
- ns-3 version
- Operating system
- Error messages
- Steps to reproduce
- Expected vs. actual behavior

## 📚 References

1. **AODV**: RFC 3561 - Ad hoc On-Demand Distance Vector Routing
2. **OLSR**: RFC 3626 - Optimized Link State Routing Protocol
3. **DSR**: RFC 4728 - The Dynamic Source Routing Protocol
4. **DSDV**: C. Perkins and P. Bhagwat, "Highly Dynamic Destination-Sequenced Distance-Vector Routing"

## 📝 License

This project is provided as-is for educational and research purposes.

## 👥 Authors

- Project created for MANET routing protocol research
- Based on ns-3 network simulator framework

## 🙏 Acknowledgments

- ns-3 development team
- MANET research community
- Protocol RFC authors

---

## 📞 Support

For questions or issues:
1. Check the [Troubleshooting](#troubleshooting) section
2. Review ns-3 documentation: https://www.nsnam.org/documentation/
3. Consult ns-3 mailing list: https://groups.google.com/g/ns-3-users

---

**Last Updated**: 2024
**Version**: 2.0
