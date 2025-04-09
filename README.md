# BPE.odin
Byte Pair Encoding algorithm written in Odin.

## Usage

**info** `[BPE]`  
 Show information about the BPE file.

**to-bpe** `[FILE] [BPE]`  
 Convert a plain text file to BPE format.

**to-file** `[BPE] [FILE]`  
 Convert a BPE file back to plain text.

**compress** `[BPE] [N]`  
 Apply BPE compression N times.

**gen-rand** `[BPE] [CNT] [LEN]`  
 Generate random text based on a BPE file.  
 Repeats **CNT** times, each with length **LEN** (in tokens).

---

## Build

For best performance, it's highly recommended to build the project with the following flags:

```bash
odin build ./src/ -o:speed -no-bounds-check
```

---

## Example

```bash
# Convert book.txt to BPE format
./src.bin to-bpe ./data/book.txt ./data/book.txt.bpe

# Compress the BPE file 5000 times
./src.bin compress ./data/book.txt.bpe 5000

# Convert the BPE file back to text
./src.bin to-file ./data/book.txt.bpe ./data/book2.txt

# Generate 10 random texts of 200 tokens each, based on book.bpe
./src.bin gen-rand ./data/book.bpe 10 200
```
