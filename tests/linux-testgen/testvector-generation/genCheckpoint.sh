#!/bin/bash

source  genSettings.sh
tcpPort=1236

instrs=8500000
checkOutDir="$outDir/checkpoint$instrs"
checkIntermedDir="$checkOutDir/intermediate-outputs"


read -p "This scripts is going to create a checkpoint at $instrs instrs.
Is that what you wanted? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
    mkdir -p $checkOutDir
    mkdir -p $checkIntermedDir
    
    # Identify instruction in trace
    instr=$(sed "${instrs}q;d" "../linux-testvectors/all.txt")
    echo "Found ${instrs}th instr: ${instr}"
    pc=$(echo $instr | cut -d " " -f1)
    asm=$(echo $instr | cut -d " " -f2)
    occurences=$(($(head -$instrs "../linux-testvectors/all.txt" | grep -c "${pc} ${asm}")-1))
    echo "It occurs ${occurences} times before the ${instrs}th instr." 

    # GDB+QEMU
    echo "Starting QEMU with attached GDB script at $(date +%H:%M:%S)"
    ($customQemu \
    -M virt \
    -nographic \
    -bios $imageDir/fw_jump.elf -kernel $imageDir/Image -append "root=/dev/vda ro" -initrd $imageDir/rootfs.cpio \
    -singlestep -rtc clock=vm -icount shift=1,align=off,sleep=on,rr=replay,rrfile="$intermedDir/$recordFile" \
    -gdb tcp::$tcpPort -S) \
    & riscv64-unknown-elf-gdb --quiet \
    -x genCheckpoint.gdb -ex "genCheckpoint $tcpPort $instrs \"$checkIntermedDir\" \"$pc\" $occurences"
    echo "Completed GDB script completed at $(date +%H:%M:%S)"

    # Post-Process GDB outputs
    ./parseState.py "$checkOutDir"
    echo "Changing Endianness at $(date +%H:%M:%S)"
    make
    ./fixBinMem "$checkIntermedDir/ramGDB.bin" "$checkOutDir/ram.bin"
    echo "Creating truncated trace at $(date +%H:%M:%S)"
    tail -n+$instrs "$outDir/$traceFile" > "$checkOutDir/$traceFile"
    echo "Checkpoint completed at $(date +%H:%M:%S)"
else
    echo "You can change the number of instructions by editing the \"instrs\" variable in this script."
    echo "Have a nice day!"
fi