# Super-Gameboy-Interface

## Description
A work in progress VHDL implementation of Super Gameboy interface. Currently needs more work to fully support decryption of all gameboy borders (that are supported) that are Super Gameboy compatible. In its current state, it can do limited DMA transactions and decode necessary pixel data from the ICDR-2 custom integrated circuit. 

Written in VHDL for Spartan-6 but can easily be ported to other vendor platforms or made completely vendor agnostic with minimal work

## Cores Currently Implemented
- Physical Layer Interface
- Transaction Layer Interface (DMA)
- Video Decoder
- Palette Encoder
- Tile Decoder
- Map Decoder

## TO-DO
- Define remaining DMA transactions
- Verify timings of various transactions
- Create PCB