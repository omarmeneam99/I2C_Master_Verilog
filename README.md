# I²C Master-Slave Communication (Verilog)

A Verilog implementation of the Inter-Integrated Circuit (I²C) protocol featuring independent I²C Master and I²C Slave controllers. The project focuses on RTL design, FSM-based control, and protocol verification through simulation.

## Features

### I²C Master

* FSM-based controller
* START and STOP condition generation
* 7-bit slave addressing with R/W bit
* ACK/NACK detection
* Multi-byte read and write transactions
* Busy, Error, and Data Ready status signals
* Tri-state SDA implementation

### I²C Slave

* FSM-based controller
* Start/Stop condition detection
* Address matching
* ACK generation
* Read and write support
* Internal 256-byte memory
* Sequential memory addressing
* Tri-state SDA implementation

## Verification

* ✔ Master testbench completed

  * Multiple Write
  * Multiple Read
  * Write → Read
  * Read → Write
  * ACK/NACK handling
* ✔ Vivado synthesis completed without errors
* ✔ Lint checks passed

## Repository Contents

| File | Description |
|------|-------------|
| `I2C_master.v` | I²C Master RTL implementation |
| `I2C_master_tb.v` | Master verification testbench |
| `I2C_Slave.v` | I²C Slave RTL implementation |
| `I2C_Master.pdf` | Master design report including implementation details and simulation waveforms |
| `I2C_Slave.pdf` | Slave design report and implementation summary |
| `run.do` | Questa/ModelSim simulation script |

## Future Work

* Complete the I²C Slave testbench.
* Develop a top-level module integrating the Master and Slave.
* Verify complete Master-Slave communication through simulation.
