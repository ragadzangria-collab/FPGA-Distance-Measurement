# FPGA-Distance-Measurement
Distance measurment using Ultra Sonic sensor and  VHDL componenets on Cyclone IV FPGA.
# FPGA-Based Distance Measurement System

![FPGA](https://img.shields.io/badge/Hardware-Altera_Cyclone_IV_DE2--115-blue)
![Language](https://img.shields.io/badge/Language-VHDL-orange)
![Protocol](https://img.shields.io/badge/Protocol-UART-green)

## 📌 Overview
This project implements a real-time **Distance Measurement System** developed on an Altera Cyclone IV FPGA board. The system utilizes an ultrasonic sensor to measure distances and transmits the real-time calculated data over a **UART communication protocol** for external monitoring and debugging.

---

## 🛠️ Key Features & Architecture
- **Ultrasonic Sensor Interface:** Designed dedicated VHDL components to trigger ultrasonic pulses and accurately measure echo pulse-width duration.
- **Digital Signal Processing & Arithmetic:** Implemented clock dividers, counters, and arithmetic blocks inside the FPGA to convert time measurements into accurate distance values (cm/inches).
- **UART Data Transmission:** Built a hardware UART transmitter module to stream distance data packets reliably to a host PC or terminal.
- **Simulation & Verification:** Verified component functionality using testbenches and simulation tools prior to hardware deployment.

### System Block Diagram


---

## 💻 Technologies & Tools
- **Hardware:** Altera DE2-115 (Cyclone IV) FPGA Board, Ultrasonic Distance Sensor (e.g., HC-SR04)
- **Language:** VHDL
- **Protocols:** UART
- **Development Tools:** Intel Quartus Prime, ModelSim

---

## 📁 Repository Structure
- `src/`               # VHDL Source Files (Ultrasonic Controller, Distance Calculator, UART Tx)
- `tb/`                # Testbench Files for Simulation and Verification
- `Project_Report.pdf` # Full design report, schematics & system architecture
- `README.md`          # Project overview and documentation


## 🚀 How to Run & Simulate
1. **Simulation:** Open the project in **ModelSim**, compile the files in the `src` and `tb` directories, and run the testbench to observe distance calculation waveforms.
2. **Synthesis:** Open the project file in **Intel Quartus Prime**, run full compilation, and program the `.sof` file onto the Cyclone IV FPGA board via USB-Blaster.

## 🎥 System Demo
[![Watch the video](https://img.shields.io/badge/Watch%20Demo-Click%20Here-red?style=for-the-badge&logo=youtube)]( https://youtu.be/wI2gc-kNnkI?si=vziH5VD4w9EUpLLt)

