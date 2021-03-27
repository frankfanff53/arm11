# ARM 11 Emulator and Assembler

## Part I: Emulator

- We are going to run this emulator via the following command line instruction:

```
./emulate add01.bin
```

- Considering this command line instruction:
  - `emulate` is the executable file, building from the `Makefile`.
  - We also need one `Makefile` for building executables.
  - `add01.bin` is the ARM 11 **binary code**.

### Task 1: Design an interface for reading input binary file

#### Implementation: Memory of the machine (for emulator)

- Firstly we should read the file line by line, and store the lines **i.e. ARM instructions** somewhere called **memory** of the machine, maybe an array in this inplementation.

- Possible problems:

  - You cannot really have a primary data structure that has a dynamic size, so to store the instructions line by line, we could either:
    - Use a linked list, and append each "instruction" at the end of the list once we have read it.
    - Use an array, with the array size subject to the maximum ARM machine memory, **64KB**. (I prefer this one).

- Given that all instructions are 32 bits and aligned on a 4-byte boundary, the memory should be implemented as a "table", with the instruction in each row, and the address of the "head" of each row, should be a multiple of 4.

- Then we could see, the memory is **an array of 8 bits unsigned integers** in this implementation, with size 2^16 = 65536. Once we want to fetch data from the memory, we should start with indices (which is a multiple of 4).

- Note that our ARM memory is _byte-addressable_, so the bytes are addressing in **big-endian** scheme.

#### Implementation: Registers of the machine (for emulator)

- Given that:
  - an ARM system has 17 registers:
    - 0 - 12 General purpose
    - 13, 14 (ignored)
    - PC register is 15
    - CPSR register is 16
    - The CPSR register is used to:
      - configure the **operating mode** of the ARM processor
      - check conditions for conditional ARM instructions
      - should be initialised as **0**
      - **IMPORTANT:** the top **four** bits carry the status flags. (the NZCV flags)
  - a register is represented as a 32-bit integer
- We need another data structure to store values in the registers (_In this case, an array of course_).
- Idea: **You might could define a C data structure (e.g. a struct)** to represent the internal state of an ARM machine.
- Note: the ARM instruction set **does not have a** _halt_ **instuction**, i.e. we need to use a `while (true)` loop in the implementation to make the processor run forever. Also, the machine should interpret an all-zero instruction as the signal of termination.
- Then we should print the value of each register, and contents (instructions) of any non-zero location.
