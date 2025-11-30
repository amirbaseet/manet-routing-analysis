#!/usr/bin/env python3
"""
MANET Routing Protocol Performance Analyzer
Analyzes CSV output from ns-3 simulations and generates detailed statistics
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
from pathlib import Path
import sys

# Set style for better-looking plots
sns.set_style("whitegrid")
plt.rcParams['figure.figsize'] = (12, 8)
plt.rcParams['font.size'] = 10

class MANETAnalyzer:
    def __init__(self, protocols=['AODV', 'OLSR', 'DSR', 'DSDV']):
        self.protocols = protocols
        self.data = {}
        self.stats = {}
        
    def load_data(self):
        """Load CSV files for all protocols"""
        print("Loading data files...")
        for protocol in self.protocols:
            filename = f"{protocol}-OUTPUT.csv"
            try:
                df = pd.read_csv(filename)
                self.data[protocol] = df
                print(f"✓ Loaded {filename}: {len(df)} rows")
            except FileNotFoundError:
                print(f"✗ Warning: {filename} not found")
                self.protocols.remove(protocol)
        
        if not self.data:
            print("Error: No data files found!")
            sys.exit(1)
    
    def calculate_statistics(self):
        """Calculate comprehensive statistics for each protocol"""
        print("\nCalculating statistics...")
        
        for protocol in self.protocols:
            df = self.data[protocol]
            
            # Calculate metrics
            stats = {
                'avg_throughput': df['ThroughputKbps'].mean(),
                'max_throughput': df['ThroughputKbps'].max(),
                'min_throughput': df['ThroughputKbps'].min(),
                'std_throughput': df['ThroughputKbps'].std(),
                
                'avg_pdr': df['PDR'].mean(),
                'min_pdr': df['PDR'].min(),
                'max_pdr': df['PDR'].max(),
                'std_pdr': df['PDR'].std(),
                
                'avg_delay': df['AvgDelay'].mean(),
                'min_delay': df['AvgDelay'].min(),
                'max_delay': df['AvgDelay'].max(),
                'std_delay': df['AvgDelay'].std(),
                
                'total_overhead': df['RoutingOverhead'].iloc[-1] if len(df) > 0 else 0,
                'avg_overhead_rate': df['RoutingOverhead'].diff().mean(),
                
                'total_packets': df['PacketsReceived'].sum(),
            }
            
            self.stats[protocol] = stats
            print(f"✓ Calculated statistics for {protocol}")
    
    def print_summary(self):
        """Print summary statistics"""
        print("\n" + "="*80)
        print("PERFORMANCE SUMMARY")
        print("="*80)
        
        # Create comparison table
        print(f"\n{'Protocol':<10} {'Avg PDR':<12} {'Avg Delay(s)':<15} {'Avg Tput(Kbps)':<18} {'Total OH':<12}")
        print("-"*80)
        
        for protocol in self.protocols:
            stats = self.stats[protocol]
            print(f"{protocol:<10} "
                  f"{stats['avg_pdr']:.4f}      "
                  f"{stats['avg_delay']:.6f}      "
                  f"{stats['avg_throughput']:.2f}           "
                  f"{stats['total_overhead']:<12.0f}")
        
        print("\n" + "="*80)
        print("DETAILED STATISTICS")
        print("="*80)
        
        for protocol in self.protocols:
            stats = self.stats[protocol]
            print(f"\n{protocol}:")
            print(f"  Throughput:")
            print(f"    Average: {stats['avg_throughput']:.2f} Kbps")
            print(f"    Min/Max: {stats['min_throughput']:.2f} / {stats['max_throughput']:.2f} Kbps")
            print(f"    Std Dev: {stats['std_throughput']:.2f} Kbps")
            
            print(f"  Packet Delivery Ratio:")
            print(f"    Average: {stats['avg_pdr']:.4f} ({stats['avg_pdr']*100:.2f}%)")
            print(f"    Min/Max: {stats['min_pdr']:.4f} / {stats['max_pdr']:.4f}")
            
            print(f"  End-to-End Delay:")
            print(f"    Average: {stats['avg_delay']:.6f} seconds")
            print(f"    Min/Max: {stats['min_delay']:.6f} / {stats['max_delay']:.6f} seconds")
            
            print(f"  Routing Overhead:")
            print(f"    Total packets: {stats['total_overhead']:.0f}")
            print(f"    Average rate: {stats['avg_overhead_rate']:.2f} packets/sec")
    
    def generate_plots(self, output_dir='plots'):
        """Generate comprehensive comparison plots"""
        Path(output_dir).mkdir(exist_ok=True)
        print(f"\nGenerating plots in '{output_dir}/' directory...")
        
        # Color palette
        colors = {'AODV': '#e41a1c', 'OLSR': '#377eb8', 
                  'DSR': '#4daf4a', 'DSDV': '#984ea3'}
        
        # 1. Time Series Plots
        fig, axes = plt.subplots(2, 2, figsize=(15, 10))
        fig.suptitle('MANET Routing Protocol Performance Comparison', fontsize=16, fontweight='bold')
        
        # Throughput
        ax = axes[0, 0]
        for protocol in self.protocols:
            df = self.data[protocol]
            ax.plot(df['Time'], df['ThroughputKbps'], 
                   label=protocol, color=colors.get(protocol, 'gray'), linewidth=2)
        ax.set_xlabel('Time (seconds)')
        ax.set_ylabel('Throughput (Kbps)')
        ax.set_title('Throughput Over Time')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        # PDR
        ax = axes[0, 1]
        for protocol in self.protocols:
            df = self.data[protocol]
            ax.plot(df['Time'], df['PDR'], 
                   label=protocol, color=colors.get(protocol, 'gray'), linewidth=2)
        ax.set_xlabel('Time (seconds)')
        ax.set_ylabel('PDR')
        ax.set_title('Packet Delivery Ratio Over Time')
        ax.set_ylim([0, 1.1])
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        # Delay
        ax = axes[1, 0]
        for protocol in self.protocols:
            df = self.data[protocol]
            ax.plot(df['Time'], df['AvgDelay'], 
                   label=protocol, color=colors.get(protocol, 'gray'), linewidth=2)
        ax.set_xlabel('Time (seconds)')
        ax.set_ylabel('Average Delay (seconds)')
        ax.set_title('End-to-End Delay Over Time')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        # Routing Overhead
        ax = axes[1, 1]
        for protocol in self.protocols:
            df = self.data[protocol]
            ax.plot(df['Time'], df['RoutingOverhead'], 
                   label=protocol, color=colors.get(protocol, 'gray'), linewidth=2)
        ax.set_xlabel('Time (seconds)')
        ax.set_ylabel('Cumulative Routing Packets')
        ax.set_title('Routing Overhead Over Time')
        ax.legend()
        ax.grid(True, alpha=0.3)
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/time_series_comparison.png', dpi=300, bbox_inches='tight')
        print(f"✓ Saved: {output_dir}/time_series_comparison.png")
        plt.close()
        
        # 2. Bar Charts for Average Performance
        fig, axes = plt.subplots(2, 2, figsize=(14, 10))
        fig.suptitle('Average Performance Metrics Comparison', fontsize=16, fontweight='bold')
        
        protocols_list = list(self.protocols)
        x_pos = np.arange(len(protocols_list))
        
        # Average Throughput
        ax = axes[0, 0]
        values = [self.stats[p]['avg_throughput'] for p in protocols_list]
        bars = ax.bar(x_pos, values, color=[colors.get(p, 'gray') for p in protocols_list])
        ax.set_xlabel('Protocol')
        ax.set_ylabel('Throughput (Kbps)')
        ax.set_title('Average Throughput')
        ax.set_xticks(x_pos)
        ax.set_xticklabels(protocols_list)
        ax.grid(True, alpha=0.3, axis='y')
        
        # Add value labels on bars
        for i, bar in enumerate(bars):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.1f}', ha='center', va='bottom')
        
        # Average PDR
        ax = axes[0, 1]
        values = [self.stats[p]['avg_pdr'] for p in protocols_list]
        bars = ax.bar(x_pos, values, color=[colors.get(p, 'gray') for p in protocols_list])
        ax.set_xlabel('Protocol')
        ax.set_ylabel('PDR')
        ax.set_title('Average Packet Delivery Ratio')
        ax.set_xticks(x_pos)
        ax.set_xticklabels(protocols_list)
        ax.set_ylim([0, 1.1])
        ax.grid(True, alpha=0.3, axis='y')
        
        for i, bar in enumerate(bars):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.3f}', ha='center', va='bottom')
        
        # Average Delay
        ax = axes[1, 0]
        values = [self.stats[p]['avg_delay'] for p in protocols_list]
        bars = ax.bar(x_pos, values, color=[colors.get(p, 'gray') for p in protocols_list])
        ax.set_xlabel('Protocol')
        ax.set_ylabel('Delay (seconds)')
        ax.set_title('Average End-to-End Delay')
        ax.set_xticks(x_pos)
        ax.set_xticklabels(protocols_list)
        ax.grid(True, alpha=0.3, axis='y')
        
        for i, bar in enumerate(bars):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.4f}', ha='center', va='bottom')
        
        # Total Routing Overhead
        ax = axes[1, 1]
        values = [self.stats[p]['total_overhead'] for p in protocols_list]
        bars = ax.bar(x_pos, values, color=[colors.get(p, 'gray') for p in protocols_list])
        ax.set_xlabel('Protocol')
        ax.set_ylabel('Total Routing Packets')
        ax.set_title('Total Routing Overhead')
        ax.set_xticks(x_pos)
        ax.set_xticklabels(protocols_list)
        ax.grid(True, alpha=0.3, axis='y')
        
        for i, bar in enumerate(bars):
            height = bar.get_height()
            ax.text(bar.get_x() + bar.get_width()/2., height,
                   f'{height:.0f}', ha='center', va='bottom')
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/average_performance.png', dpi=300, bbox_inches='tight')
        print(f"✓ Saved: {output_dir}/average_performance.png")
        plt.close()
        
        # 3. Box Plots for Distribution Analysis
        fig, axes = plt.subplots(2, 2, figsize=(14, 10))
        fig.suptitle('Performance Distribution Analysis', fontsize=16, fontweight='bold')
        
        # Throughput distribution
        ax = axes[0, 0]
        data_to_plot = [self.data[p]['ThroughputKbps'].values for p in protocols_list]
        bp = ax.boxplot(data_to_plot, labels=protocols_list, patch_artist=True)
        for patch, protocol in zip(bp['boxes'], protocols_list):
            patch.set_facecolor(colors.get(protocol, 'gray'))
        ax.set_ylabel('Throughput (Kbps)')
        ax.set_title('Throughput Distribution')
        ax.grid(True, alpha=0.3, axis='y')
        
        # PDR distribution
        ax = axes[0, 1]
        data_to_plot = [self.data[p]['PDR'].values for p in protocols_list]
        bp = ax.boxplot(data_to_plot, labels=protocols_list, patch_artist=True)
        for patch, protocol in zip(bp['boxes'], protocols_list):
            patch.set_facecolor(colors.get(protocol, 'gray'))
        ax.set_ylabel('PDR')
        ax.set_title('PDR Distribution')
        ax.grid(True, alpha=0.3, axis='y')
        
        # Delay distribution
        ax = axes[1, 0]
        data_to_plot = [self.data[p]['AvgDelay'].values for p in protocols_list]
        bp = ax.boxplot(data_to_plot, labels=protocols_list, patch_artist=True)
        for patch, protocol in zip(bp['boxes'], protocols_list):
            patch.set_facecolor(colors.get(protocol, 'gray'))
        ax.set_ylabel('Delay (seconds)')
        ax.set_title('Delay Distribution')
        ax.grid(True, alpha=0.3, axis='y')
        
        # Remove empty subplot
        fig.delaxes(axes[1, 1])
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/distribution_analysis.png', dpi=300, bbox_inches='tight')
        print(f"✓ Saved: {output_dir}/distribution_analysis.png")
        plt.close()
        
        # 4. Correlation Heatmap
        fig, axes = plt.subplots(1, len(protocols_list), figsize=(16, 4))
        if len(protocols_list) == 1:
            axes = [axes]
        
        fig.suptitle('Metric Correlation Analysis', fontsize=16, fontweight='bold')
        
        for idx, protocol in enumerate(protocols_list):
            df = self.data[protocol]
            corr_cols = ['ThroughputKbps', 'PDR', 'AvgDelay', 'RoutingOverhead']
            corr_matrix = df[corr_cols].corr()
            
            sns.heatmap(corr_matrix, annot=True, fmt='.2f', cmap='coolwarm', 
                       center=0, square=True, ax=axes[idx], cbar_kws={'shrink': 0.8})
            axes[idx].set_title(f'{protocol}')
        
        plt.tight_layout()
        plt.savefig(f'{output_dir}/correlation_heatmap.png', dpi=300, bbox_inches='tight')
        print(f"✓ Saved: {output_dir}/correlation_heatmap.png")
        plt.close()
        
        print(f"\n✓ All plots generated successfully!")
    
    def save_statistics(self, filename='statistics_summary.txt'):
        """Save statistics to a text file"""
        with open(filename, 'w') as f:
            f.write("="*80 + "\n")
            f.write("MANET ROUTING PROTOCOL PERFORMANCE ANALYSIS\n")
            f.write("="*80 + "\n\n")
            
            f.write("COMPARATIVE SUMMARY\n")
            f.write("-"*80 + "\n")
            f.write(f"{'Protocol':<10} {'Avg PDR':<12} {'Avg Delay(s)':<15} {'Avg Tput(Kbps)':<18} {'Total OH':<12}\n")
            f.write("-"*80 + "\n")
            
            for protocol in self.protocols:
                stats = self.stats[protocol]
                f.write(f"{protocol:<10} "
                       f"{stats['avg_pdr']:.4f}      "
                       f"{stats['avg_delay']:.6f}      "
                       f"{stats['avg_throughput']:.2f}           "
                       f"{stats['total_overhead']:<12.0f}\n")
            
            f.write("\n" + "="*80 + "\n")
            f.write("DETAILED STATISTICS\n")
            f.write("="*80 + "\n")
            
            for protocol in self.protocols:
                stats = self.stats[protocol]
                f.write(f"\n{protocol}:\n")
                f.write(f"  Throughput:\n")
                f.write(f"    Average: {stats['avg_throughput']:.2f} Kbps\n")
                f.write(f"    Min/Max: {stats['min_throughput']:.2f} / {stats['max_throughput']:.2f} Kbps\n")
                f.write(f"    Std Dev: {stats['std_throughput']:.2f} Kbps\n")
                
                f.write(f"  Packet Delivery Ratio:\n")
                f.write(f"    Average: {stats['avg_pdr']:.4f} ({stats['avg_pdr']*100:.2f}%)\n")
                f.write(f"    Min/Max: {stats['min_pdr']:.4f} / {stats['max_pdr']:.4f}\n")
                
                f.write(f"  End-to-End Delay:\n")
                f.write(f"    Average: {stats['avg_delay']:.6f} seconds\n")
                f.write(f"    Min/Max: {stats['min_delay']:.6f} / {stats['max_delay']:.6f} seconds\n")
                
                f.write(f"  Routing Overhead:\n")
                f.write(f"    Total packets: {stats['total_overhead']:.0f}\n")
                f.write(f"    Average rate: {stats['avg_overhead_rate']:.2f} packets/sec\n")
        
        print(f"\n✓ Statistics saved to {filename}")

def main():
    print("="*80)
    print("MANET Routing Protocol Performance Analyzer")
    print("="*80)
    
    # Create analyzer
    analyzer = MANETAnalyzer()
    
    # Load data
    analyzer.load_data()
    
    # Calculate statistics
    analyzer.calculate_statistics()
    
    # Print summary
    analyzer.print_summary()
    
    # Generate plots
    analyzer.generate_plots()
    
    # Save statistics
    analyzer.save_statistics()
    
    print("\n" + "="*80)
    print("Analysis Complete!")
    print("="*80)

if __name__ == "__main__":
    main()
