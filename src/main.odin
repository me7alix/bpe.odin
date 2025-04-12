package main

import "core:fmt"
import "core:os"
import "core:strings"
import "core:strconv"

main :: proc() {
  undefCommand := true

  if len(os.args) == 4 {
    if os.args[1] == "to-bpe" {
      tokenizer := tokenizer_from_file(os.args[2])
      defer tokenizer_free(tokenizer)
      tokenizer_write_bpe(tokenizer, os.args[3])
      undefCommand = false
    } else if os.args[1] == "to-file" {
      tokenizer := tokenizer_read_bpe(os.args[2])
      defer tokenizer_free(tokenizer)
      tokenizer_to_file(&tokenizer, os.args[3])
      undefCommand = false
    } else if os.args[1] == "compress" { 
      tokenizer := tokenizer_read_bpe(os.args[2])
      defer tokenizer_free(tokenizer)
      iter_cnt := strconv.atoi(os.args[3])
      for i := 0; i < iter_cnt; i+=1 {
        tokenizer_iter(&tokenizer)
        if i % (max(iter_cnt / 20, 1)) == 0 {
          file_size := 8 + len(tokenizer.table) * 4 + len(tokenizer.tokens) * 2
          fmt.println(i*100/iter_cnt, "%", " ", file_size, " bytes ", sep = "") 
        }
      }
      tokenizer_write_bpe(tokenizer, os.args[2])
      undefCommand = false
    }
  } else if len(os.args) == 5 {
    if os.args[1] == "gen-rand" {
      tokenizer := tokenizer_read_bpe(os.args[2])
      defer tokenizer_free(tokenizer)
      cnt := strconv.atoi(os.args[3])
      lenght := strconv.atoi(os.args[4])
      for i := 0; i < cnt; i+=1 {
        fmt.println("\n--------------------------------")
        tokenizer_generate_random_text(&tokenizer, lenght)
      }
      undefCommand = false
    } 
  } else if len(os.args) == 3 {
    if os.args[1] == "info" {
      tokenizer := tokenizer_read_bpe(os.args[2])
      defer tokenizer_free(tokenizer)
      file_size := 8 + len(tokenizer.table) * 4 + len(tokenizer.tokens) * 2
      fmt.println("tokens:", len(tokenizer.tokens))
      fmt.println("table:", len(tokenizer.table))
      fmt.println("size (bytes):", file_size)
      undefCommand = false
    }
  } else if len(os.args) == 1 || undefCommand {
    fmt.println("Available Commands:")
    fmt.println("  info      [BPE]               Show BPE information")
    fmt.println("  to-bpe    [FILE] [BPE]        Convert a file to BPE format")
    fmt.println("  to-file   [BPE] [FILE]        Convert a BPE back to file")
    fmt.println("  compress  [BPE] [N]           Apply BPE compression N times")
    fmt.println("  gen-rand  [BPE] [CNT] [LEN]   Generate random text based on BPE")
    fmt.println("                                Repeats CNT times with LEN length")
  }
}
