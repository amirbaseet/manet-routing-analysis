# ============================================================================
# MANET Routing Protocol Comparison - Gnuplot Visualization
# ============================================================================
# This script generates comprehensive comparison plots for AODV, OLSR, DSR, DSDV
# ============================================================================

# Global settings
set terminal pdfcairo enhanced font "Arial,10" size 10,12
set output "MANET-Comparison.pdf"
set datafile separator ","

# Define line styles for consistency
set style line 1 lc rgb '#e41a1c' lt 1 lw 2 pt 7 ps 0.5  # Red - AODV
set style line 2 lc rgb '#377eb8' lt 1 lw 2 pt 9 ps 0.5  # Blue - OLSR
set style line 3 lc rgb '#4daf4a' lt 1 lw 2 pt 5 ps 0.5  # Green - DSR
set style line 4 lc rgb '#984ea3' lt 1 lw 2 pt 11 ps 0.5 # Purple - DSDV

# Set multiplot layout
set multiplot layout 3,2 title "MANET Routing Protocol Performance Comparison" font ",14"

#########################################################
# 1) Throughput Comparison
#########################################################
set title "Throughput Over Time"
set xlabel "Time (seconds)"
set ylabel "Throughput (Kbps)"
set grid
set key top left

plot "AODV-OUTPUT.csv" every ::1 using 1:2 with lines ls 1 title "AODV", \
     "OLSR-OUTPUT.csv" every ::1 using 1:2 with lines ls 2 title "OLSR", \
     "DSR-OUTPUT.csv"  every ::1 using 1:2 with lines ls 3 title "DSR", \
     "DSDV-OUTPUT.csv" every ::1 using 1:2 with lines ls 4 title "DSDV"

#########################################################
# 2) Packet Delivery Ratio Comparison
#########################################################
set title "Packet Delivery Ratio (PDR) Over Time"
set xlabel "Time (seconds)"
set ylabel "PDR"
set yrange [0:1.1]
set grid
set key bottom right

plot "AODV-OUTPUT.csv" every ::1 using 1:7 with lines ls 1 title "AODV", \
     "OLSR-OUTPUT.csv" every ::1 using 1:7 with lines ls 2 title "OLSR", \
     "DSR-OUTPUT.csv"  every ::1 using 1:7 with lines ls 3 title "DSR", \
     "DSDV-OUTPUT.csv" every ::1 using 1:7 with lines ls 4 title "DSDV"

#########################################################
# 3) End-to-End Delay Comparison
#########################################################
set title "Average End-to-End Delay"
set xlabel "Time (seconds)"
set ylabel "Delay (seconds)"
set autoscale y
set grid
set key top right

plot "AODV-OUTPUT.csv" every ::1 using 1:8 with lines ls 1 title "AODV", \
     "OLSR-OUTPUT.csv" every ::1 using 1:8 with lines ls 2 title "OLSR", \
     "DSR-OUTPUT.csv"  every ::1 using 1:8 with lines ls 3 title "DSR", \
     "DSDV-OUTPUT.csv" every ::1 using 1:8 with lines ls 4 title "DSDV"

#########################################################
# 4) Routing Overhead Comparison
#########################################################
set title "Cumulative Routing Overhead"
set xlabel "Time (seconds)"
set ylabel "Routing Packets"
set autoscale y
set grid
set key top left

plot "AODV-OUTPUT.csv" every ::1 using 1:9 with lines ls 1 title "AODV", \
     "OLSR-OUTPUT.csv" every ::1 using 1:9 with lines ls 2 title "OLSR", \
     "DSR-OUTPUT.csv"  every ::1 using 1:9 with lines ls 3 title "DSR", \
     "DSDV-OUTPUT.csv" every ::1 using 1:9 with lines ls 4 title "DSDV"

#########################################################
# 5) Packets Received Comparison
#########################################################
set title "Cumulative Packets Received"
set xlabel "Time (seconds)"
set ylabel "Packets Received"
set autoscale y
set grid
set key top left

plot "AODV-OUTPUT.csv" every ::1 using 1:3 with lines ls 1 title "AODV", \
     "OLSR-OUTPUT.csv" every ::1 using 1:3 with lines ls 2 title "OLSR", \
     "DSR-OUTPUT.csv"  every ::1 using 1:3 with lines ls 3 title "DSR", \
     "DSDV-OUTPUT.csv" every ::1 using 1:3 with lines ls 4 title "DSDV"

#########################################################
# 6) Average Performance Summary (Bar Chart)
#########################################################
#########################################################
##########################################################
# 6) Average Performance Summary (Bar Chart)
#########################################################
set title "Average Performance Metrics"
set xlabel "Protocol"
set ylabel "Normalized Value"
set style data histogram
set style histogram cluster gap 2
set style fill solid border -1
set boxwidth 0.6
set grid ytics

set key top left

# Show notes on interpretation
set label 1 "Higher is better for PDR and Throughput" at graph 0.5, 0.95 center
set label 2 "Lower is better for Delay and Overhead" at graph 0.5, 0.90 center

set yrange [0:1.2]

# === This is the ONLY valid plot. DO NOT add the old one ===
plot "average_metrics.dat" using 2:xtic(1) title "AODV", \
     "" using 3 title "OLSR", \
     "" using 4 title "DSR", \
     "" using 5 title "DSDV"

# Generate individual PDFs for each metric (optional)
# ============================================================================

#########################################################
# Individual Plot 1: Throughput
#########################################################
set terminal pdfcairo enhanced font "Arial,12" size 8,6
set output "Throughput-Comparison.pdf"
reset
set datafile separator ","
set title "Throughput Comparison - MANET Routing Protocols" font ",14"
set xlabel "Time (seconds)" font ",12"
set ylabel "Throughput (Kbps)" font ",12"
set grid
set key top left box
set style line 1 lc rgb '#e41a1c' lt 1 lw 2.5
set style line 2 lc rgb '#377eb8' lt 1 lw 2.5
set style line 3 lc rgb '#4daf4a' lt 1 lw 2.5
set style line 4 lc rgb '#984ea3' lt 1 lw 2.5

plot "AODV-OUTPUT.csv" every ::1 using 1:2 with lines ls 1 title "AODV", \
     "OLSR-OUTPUT.csv" every ::1 using 1:2 with lines ls 2 title "OLSR", \
     "DSR-OUTPUT.csv"  every ::1 using 1:2 with lines ls 3 title "DSR", \
     "DSDV-OUTPUT.csv" every ::1 using 1:2 with lines ls 4 title "DSDV"

#########################################################
# Individual Plot 2: PDR
#########################################################
set output "PDR-Comparison.pdf"
reset
set datafile separator ","
set title "Packet Delivery Ratio Comparison" font ",14"
set xlabel "Time (seconds)" font ",12"
set ylabel "PDR" font ",12"
set yrange [0:1.1]
set grid
set key bottom right box
set style line 1 lc rgb '#e41a1c' lt 1 lw 2.5
set style line 2 lc rgb '#377eb8' lt 1 lw 2.5
set style line 3 lc rgb '#4daf4a' lt 1 lw 2.5
set style line 4 lc rgb '#984ea3' lt 1 lw 2.5

plot "AODV-OUTPUT.csv" every ::1 using 1:7 with lines ls 1 title "AODV", \
     "OLSR-OUTPUT.csv" every ::1 using 1:7 with lines ls 2 title "OLSR", \
     "DSR-OUTPUT.csv"  every ::1 using 1:7 with lines ls 3 title "DSR", \
     "DSDV-OUTPUT.csv" every ::1 using 1:7 with lines ls 4 title "DSDV"

#########################################################
# Individual Plot 3: Delay
#########################################################
set output "Delay-Comparison.pdf"
reset
set datafile separator ","
set title "End-to-End Delay Comparison" font ",14"
set xlabel "Time (seconds)" font ",12"
set ylabel "Average Delay (seconds)" font ",12"
set autoscale y
set grid
set key top right box
set style line 1 lc rgb '#e41a1c' lt 1 lw 2.5
set style line 2 lc rgb '#377eb8' lt 1 lw 2.5
set style line 3 lc rgb '#4daf4a' lt 1 lw 2.5
set style line 4 lc rgb '#984ea3' lt 1 lw 2.5

plot "AODV-OUTPUT.csv" every ::1 using 1:8 with lines ls 1 title "AODV", \
     "OLSR-OUTPUT.csv" every ::1 using 1:8 with lines ls 2 title "OLSR", \
     "DSR-OUTPUT.csv"  every ::1 using 1:8 with lines ls 3 title "DSR", \
     "DSDV-OUTPUT.csv" every ::1 using 1:8 with lines ls 4 title "DSDV"

#########################################################
# Individual Plot 4: Routing Overhead
#########################################################
set output "Overhead-Comparison.pdf"
reset
set datafile separator ","
set title "Routing Overhead Comparison" font ",14"
set xlabel "Time (seconds)" font ",12"
set ylabel "Cumulative Routing Packets" font ",12"
set autoscale y
set grid
set key top left box
set style line 1 lc rgb '#e41a1c' lt 1 lw 2.5
set style line 2 lc rgb '#377eb8' lt 1 lw 2.5
set style line 3 lc rgb '#4daf4a' lt 1 lw 2.5
set style line 4 lc rgb '#984ea3' lt 1 lw 2.5

plot "AODV-OUTPUT.csv" every ::1 using 1:9 with lines ls 1 title "AODV", \
     "OLSR-OUTPUT.csv" every ::1 using 1:9 with lines ls 2 title "OLSR", \
     "DSR-OUTPUT.csv"  every ::1 using 1:9 with lines ls 3 title "DSR", \
     "DSDV-OUTPUT.csv" every ::1 using 1:9 with lines ls 4 title "DSDV"
