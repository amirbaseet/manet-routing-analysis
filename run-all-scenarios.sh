#!/bin/bash
# ============================================================================
# Run All 3 Scenarios Automatically
# ============================================================================
# This script runs:
# - Scenario 1: Default (moderate mobility, 3 m/s)
# - Scenario 2: Low Mobility (1 m/s)
# - Scenario 3: High Mobility (10 m/s)
# ============================================================================

set -e  # Exit on error

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
SIM="routing-analysis"
PROTOCOLS=("AODV" "OLSR" "DSR" "DSDV")
NODES=25
SINKS=5
SIMTIME=200

# ============================================================================
# Functions
# ============================================================================

print_header() {
    echo ""
    echo -e "${BLUE}============================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}============================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${YELLOW}→ $1${NC}"
}

run_protocol() {
    local protocol=$1
    local speed=$2
    local scenario_name=$3
    
    print_info "Running $protocol ($scenario_name)..."
    
    if ./ns3 run "$SIM --protocol=$protocol --nWifis=$NODES --nSinks=$SINKS --nodeSpeed=$speed --totalTime=$SIMTIME" > /dev/null 2>&1; then
        if [[ -f "${protocol}-OUTPUT.csv" ]]; then
            print_success "$protocol completed"
        else
            print_error "$protocol failed to generate CSV"
            return 1
        fi
    else
        print_error "$protocol simulation failed"
        return 1
    fi
}

save_results() {
    local scenario_dir=$1
    
    print_info "Generating plots..."
    gnuplot compare.gnuplot 2>/dev/null
    
    print_info "Running statistical analysis..."
    python3 analyze_results.py > /dev/null 2>&1
    
    print_info "Saving results to $scenario_dir..."
    cp *-OUTPUT.csv "$scenario_dir/"
    cp MANET-Comparison.pdf "$scenario_dir/"
    cp *-ANIM.xml "$scenario_dir/" 2>/dev/null || true
    cp statistics_summary.txt "$scenario_dir/"
    cp -r plots "$scenario_dir/" 2>/dev/null || true
    
    print_success "Results saved"
}

cleanup() {
    rm -f *-OUTPUT.csv *-ANIM.xml *.pdf statistics_summary.txt 2>/dev/null || true
    rm -rf plots/ 2>/dev/null || true
}

show_summary() {
    local scenario=$1
    local stats_file=$2
    
    echo ""
    echo -e "${BLUE}Results for $scenario:${NC}"
    echo "----------------------------------------"
    if [[ -f "$stats_file" ]]; then
        grep -A 5 "COMPARATIVE SUMMARY" "$stats_file" | tail -6
    else
        echo "Statistics file not found"
    fi
}

# ============================================================================
# Main Execution
# ============================================================================

print_header "MANET 3-Scenario Comparison Suite"
echo "Nodes: $NODES | Flows: $SINKS | Duration: ${SIMTIME}s"
echo "Protocols: ${PROTOCOLS[@]}"
echo ""
echo "Scenarios:"
echo "  1. Default (Speed: 0-3 m/s)"
echo "  2. Low Mobility (Speed: 0-1 m/s)"
echo "  3. High Mobility (Speed: 0-10 m/s)"
echo ""

# Create directory structure
mkdir -p results/{scenario1_default,scenario2_low_mobility,scenario3_high_mobility}

# Build ns-3
print_header "Building ns-3"
if ./ns3 build > /dev/null 2>&1; then
    print_success "Build successful"
else
    print_error "Build failed"
    exit 1
fi

# Record start time
START_TIME=$(date +%s)

# ============================================================================
# SCENARIO 1: DEFAULT (Moderate Mobility)
# ============================================================================
print_header "SCENARIO 1: Default Configuration (3 m/s)"
cleanup

for PROTO in "${PROTOCOLS[@]}"; do
    run_protocol "$PROTO" 3.0 "Default"
done

save_results "results/scenario1_default"
show_summary "Scenario 1" "results/scenario1_default/statistics_summary.txt"

# ============================================================================
# SCENARIO 2: LOW MOBILITY
# ============================================================================
print_header "SCENARIO 2: Low Mobility (1 m/s)"
cleanup

for PROTO in "${PROTOCOLS[@]}"; do
    run_protocol "$PROTO" 1.0 "Low Mobility"
done

save_results "results/scenario2_low_mobility"
show_summary "Scenario 2" "results/scenario2_low_mobility/statistics_summary.txt"

# ============================================================================
# SCENARIO 3: HIGH MOBILITY
# ============================================================================
print_header "SCENARIO 3: High Mobility (10 m/s)"
cleanup

for PROTO in "${PROTOCOLS[@]}"; do
    run_protocol "$PROTO" 10.0 "High Mobility"
done

save_results "results/scenario3_high_mobility"
show_summary "Scenario 3" "results/scenario3_high_mobility/statistics_summary.txt"

# ============================================================================
# Final Cleanup
# ============================================================================
cleanup

# Calculate total time
END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))
MINUTES=$((DURATION / 60))
SECONDS=$((DURATION % 60))

# ============================================================================
# Summary Report
# ============================================================================
print_header "ALL SCENARIOS COMPLETE!"

echo ""
echo "Total execution time: ${MINUTES}m ${SECONDS}s"
echo ""
echo "Results saved in:"
echo "  → results/scenario1_default/"
echo "  → results/scenario2_low_mobility/"
echo "  → results/scenario3_high_mobility/"
echo ""
echo "Each directory contains:"
echo "  - CSV files with raw data"
echo "  - MANET-Comparison.pdf (plots)"
echo "  - statistics_summary.txt (detailed stats)"
echo "  - plots/ directory (Python visualizations)"
echo ""

# Generate comparison summary
print_header "Generating Cross-Scenario Comparison"

SUMMARY_FILE="results/FINAL_COMPARISON.txt"

cat > "$SUMMARY_FILE" << 'EOF'
================================================================================
MANET ROUTING PROTOCOL COMPARISON
CROSS-SCENARIO ANALYSIS
================================================================================

SCENARIO 1: DEFAULT (Speed: 0-3 m/s)
----------------------------------------
EOF

if [[ -f "results/scenario1_default/statistics_summary.txt" ]]; then
    grep -A 5 "Protocol" "results/scenario1_default/statistics_summary.txt" | head -6 >> "$SUMMARY_FILE"
fi

cat >> "$SUMMARY_FILE" << 'EOF'

SCENARIO 2: LOW MOBILITY (Speed: 0-1 m/s)
----------------------------------------
EOF

if [[ -f "results/scenario2_low_mobility/statistics_summary.txt" ]]; then
    grep -A 5 "Protocol" "results/scenario2_low_mobility/statistics_summary.txt" | head -6 >> "$SUMMARY_FILE"
fi

cat >> "$SUMMARY_FILE" << 'EOF'

SCENARIO 3: HIGH MOBILITY (Speed: 0-10 m/s)
----------------------------------------
EOF

if [[ -f "results/scenario3_high_mobility/statistics_summary.txt" ]]; then
    grep -A 5 "Protocol" "results/scenario3_high_mobility/statistics_summary.txt" | head -6 >> "$SUMMARY_FILE"
fi

cat >> "$SUMMARY_FILE" << 'EOF'

================================================================================
KEY OBSERVATIONS:
================================================================================

1. PACKET DELIVERY RATIO (PDR):
   - Best overall: [ANALYZE YOUR RESULTS]
   - Most stable across scenarios: [ANALYZE YOUR RESULTS]
   - Most affected by mobility: [ANALYZE YOUR RESULTS]

2. END-TO-END DELAY:
   - Lowest delay: [ANALYZE YOUR RESULTS]
   - Most affected by mobility: [ANALYZE YOUR RESULTS]

3. THROUGHPUT:
   - Highest throughput: [ANALYZE YOUR RESULTS]
   - Most consistent: [ANALYZE YOUR RESULTS]

4. ROUTING OVERHEAD:
   - Lowest overhead: [ANALYZE YOUR RESULTS]
   - Overhead scaling with mobility: [ANALYZE YOUR RESULTS]

================================================================================
RECOMMENDATIONS:
================================================================================

Low Mobility Networks:    [YOUR RECOMMENDATION]
High Mobility Networks:   [YOUR RECOMMENDATION]
Delay-Sensitive Apps:     [YOUR RECOMMENDATION]
Large-Scale Networks:     [YOUR RECOMMENDATION]

================================================================================
EOF

print_success "Final comparison saved to: $SUMMARY_FILE"
cat "$SUMMARY_FILE"

echo ""
print_header "Next Steps"
echo "1. Review results in results/ directory"
echo "2. Open PDF plots: xdg-open results/scenario1_default/MANET-Comparison.pdf"
echo "3. Analyze statistics: cat results/FINAL_COMPARISON.txt"
echo "4. Use these results to write your research paper"
echo ""

print_success "All done! 🎉"
