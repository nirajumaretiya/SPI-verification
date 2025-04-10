# SPI Verification Project

![SPI Protocol](https://img.shields.io/badge/Protocol-SPI-blue)
![SystemVerilog](https://img.shields.io/badge/Language-SystemVerilog-orange)
![Verification](https://img.shields.io/badge/Verification-UVM--like-green)

## 📋 Overview

This project implements and verifies a Serial Peripheral Interface (SPI) communication system using SystemVerilog. The implementation includes both master and slave components with a comprehensive verification environment.

## 🏗️ Project Structure

```
SPI-verification/
├── src/
│   └── top.sv           # Main SPI implementation (Master + Slave)
├── test/
│   └── testbench.sv     # Verification environment
└── README.md            # Project documentation
```

## 🎯 Features

### SPI Implementation
- 12-bit data width
- Master and Slave components
- Configurable clock divider
- Synchronous reset
- State machine-based control

### Verification Environment
- Transaction-level modeling
- Random stimulus generation
- Scoreboard-based checking
- Event-driven synchronization
- Waveform dumping support

## 🛠️ Components

### Design (src/top.sv)
- **SPI Master**
  - Clock generation
  - Data transmission
  - Chip select control
  - State machine control

- **SPI Slave**
  - Data reception
  - Done signal generation
  - State machine control

### Testbench (test/testbench.sv)
- **Transaction Class**
  - Data packet handling
  - Randomization support
  - Deep copy functionality

- **Generator**
  - Random transaction generation
  - Mailbox-based communication
  - Event synchronization

- **Driver**
  - Transaction to signal conversion
  - Reset sequence handling
  - Interface driving

- **Monitor**
  - Output capture
  - Data collection
  - Scoreboard communication

- **Scoreboard**
  - Data comparison
  - Result checking
  - Test status reporting

- **Environment**
  - Component coordination
  - Test flow control
  - Resource management

## 🚀 Getting Started

### Prerequisites
- SystemVerilog simulator (ModelSim, VCS, or Icarus Verilog)
- Basic understanding of SPI protocol
- Familiarity with SystemVerilog

### Simulation Steps
1. Compile the design and testbench:
   ```bash
   vlog src/top.sv test/testbench.sv
   ```

2. Run the simulation:
   ```bash
   vsim -c tb
   ```

3. View waveforms (optional):
   ```bash
   gtkwave dump.vcd
   ```

## 📊 Verification Results

The testbench will display:
- Generated stimulus
- Transmitted data
- Received data
- Comparison results
- Test status

## 🔍 Debugging

Common debug points:
- Clock generation
- Reset sequence
- Data transmission
- State machine transitions
- Scoreboard comparisons

## 📝 Notes

- The testbench generates 4 random transactions by default
- Waveforms are saved in `dump.vcd`
- All signals are synchronized to the system clock

## 🤝 Contributing

Feel free to:
- Report issues
- Suggest improvements
- Submit pull requests

## 📄 License

This project is open-source and available under the MIT License.

## 🙏 Acknowledgments

- SystemVerilog community
- UVM methodology
- Open-source verification tools
