package main

import "core:fmt"
import "core:math/rand"
import "core:time"
import "core:os"

NULL_TOKEN :: 0xFFFF

Token :: u16

Pair :: struct {
  l, r: Token,
}

Tokenizer :: struct {
  tokens: [dynamic]Token,
  table: [dynamic]Pair,
}

token_print :: proc(leafs: ^[dynamic]Pair, tokenizer: ^Tokenizer, tok: Token) {
  pair := tokenizer.table[tok]

  if pair.r == NULL_TOKEN {
    fmt.printf("%c", pair.l)
    return
  }

  clear(leafs)
  pair_get_leafs(leafs, tokenizer, tokenizer.table[pair.l])
  pair_get_leafs(leafs, tokenizer, tokenizer.table[pair.r])
  for leaf in leafs {
    fmt.printf("%c", leaf.l)
  }
}

tokenizer_generate_random_text :: proc(tokenizer: ^Tokenizer, length: int) {
  seed := time.now()._nsec;
  rand.reset(u64(seed));

  table := tokenizer.table
  tok_ind := u16(rand.int_max(len(table)))
  skipPrint := false
  vars := make([dynamic]Token)
  defer delete(vars)

  leafs := make([dynamic]Pair)
  defer delete(leafs)

  for iter := 0; iter < length; iter+=1 {
    if tok_ind == NULL_TOKEN {
      break
    }

    if !skipPrint {
      token_print(&leafs, tokenizer, tok_ind)
    }

    clear(&vars)
    for i := 0; i < len(table); i+=1 {
      if table[i].l == tok_ind {
        append(&vars, table[i].r)
      }
    }

    if len(vars) > 0 {
      tok_ind = rand.choice(vars[:])
      skipPrint = false
      continue
    }

    tok_ind = table[tok_ind].r
    skipPrint = true
  } 
}

pair_get_leafs :: proc(res: ^[dynamic]Pair, tokenizer: ^Tokenizer, pair: Pair) {
  if pair.r == NULL_TOKEN {
    append(res, pair)
    return
  } 

  pair_get_leafs(res, tokenizer, tokenizer.table[pair.l])
  pair_get_leafs(res, tokenizer, tokenizer.table[pair.r])
}

tokenizer_print_table :: proc(tokenizer: ^Tokenizer) {
  leafs := make([dynamic]Pair, 0, 5)
  defer delete(leafs)
  
  for token in tokenizer.table { 
    clear(&leafs)
    pair_get_leafs(&leafs, tokenizer, token)

    for leaf in leafs {
      fmt.printf("%c", leaf.l)
    }

    fmt.print("|")
  }
}

tokenizer_from_string :: proc(str: string) -> Tokenizer {
  tokenizer := Tokenizer{
    make([dynamic]Token, 0, len(str)),
    make([dynamic]Pair, 0, 512),
  }

  ht := make(map[Pair]u16)
  defer delete(ht)

  for char in str {
    tok := Pair{u16(char), NULL_TOKEN} 
    ind, ok := ht[tok]
    if !ok {
      append(&tokenizer.table, tok)
      ht[tok] = u16(len(tokenizer.table) - 1)
      append(&tokenizer.tokens, ht[tok])
    } else {
      append(&tokenizer.tokens, ind)
    }
  }

  return tokenizer
}

tokenizer_to_file :: proc(tokenizer: ^Tokenizer, filename: string) {
  data := make([dynamic]byte)
  defer delete(data)
  leafs := make([dynamic]Pair)

  for tokPtr in tokenizer.tokens {
    clear(&leafs)
    pair_get_leafs(&leafs, tokenizer, tokenizer.table[tokPtr])
    for leaf in leafs {
      append(&data, u8(leaf.l)) 
    }
  }

  os.write_entire_file(filename, data[:]) 
}

tokenizer_from_file :: proc(filename: string) -> Tokenizer { 
  file, file_ok := os.read_entire_file(filename, context.allocator)
  ensure(file_ok)

  tokenizer := Tokenizer{
    make([dynamic]Token, 0, len(file)),
    make([dynamic]Pair, 0, 512),
  }

  ht := make(map[Pair]Token)
  defer delete(ht)

  for bt in file {
    tok := Pair{Token(bt), NULL_TOKEN} 
    ind, ok := ht[tok]
    if !ok {
      append(&tokenizer.table, tok)
      ht[tok] = Token(len(tokenizer.table) - 1)
      append(&tokenizer.tokens, ht[tok])
    } else {
      append(&tokenizer.tokens, ind)
    }
  }

  return tokenizer
}

tokenizer_free :: proc(tokenizer: Tokenizer) {
  delete(tokenizer.tokens)
  delete(tokenizer.table)
}

tokenizer_iter :: proc(tokenizer: ^Tokenizer) {
  most_freq_pair := Pair{}
  most_freq_cnt := u32(0)
  ht := make(map[Pair]u32)
  defer delete(ht)

  for i := 0; i < len(tokenizer.tokens)-1; i+=1 {
    pair := Pair{tokenizer.tokens[i], tokenizer.tokens[i+1]}
    _, ok := ht[pair] 
    if ok { 
      ht[pair] += 1
    } else {
      ht[pair] = 1
    }

    if ht[pair] > most_freq_cnt {
      most_freq_pair = pair
      most_freq_cnt = ht[pair]
    }
  }

  append(&tokenizer.table, most_freq_pair)
  new_token_ind := u16(len(tokenizer.table) - 1)

  for i := 0; i < len(tokenizer.tokens)-1; i+=1 {
    if tokenizer.tokens[i] == most_freq_pair.l &&
       tokenizer.tokens[i+1] == most_freq_pair.r {
      tokenizer.tokens[i] = new_token_ind
      ordered_remove(&tokenizer.tokens, i+1)
    }
  }
}

tokenizer_write_bpe :: proc(tokenizer: Tokenizer, filename: string) {
  data := make([dynamic]byte)
  defer delete(data)

  b4 := transmute([4]byte)(u32(len(tokenizer.table)))
  append(&data, ..b4[:])
  b4 = transmute([4]byte)(u32(len(tokenizer.tokens)))
  append(&data, ..b4[:])

  b2 := transmute([2]byte)(u16(0))

  for token in tokenizer.table {
    b2 = transmute([2]byte)(token.l)
    append(&data, ..b2[:])
    b2 = transmute([2]byte)(token.r)
    append(&data, ..b2[:])
  }

  for tokPtr in tokenizer.tokens {
    b2 = transmute([2]byte)(tokPtr)
    append(&data, ..b2[:])
  }

  os.write_entire_file(filename, data[:]) 
}

bytes_to_u32 :: proc(bytes: []u8) -> u32 {
  arr: [4]u8 = [4]u8{       
    bytes[0], bytes[1],
    bytes[2], bytes[3],
  }
  return transmute(u32)(arr)
}

bytes_to_u16 :: proc(bytes: []u8) -> u16 {
  arr: [2]u8 = [2]u8{       
    bytes[0], bytes[1],
  }
  return transmute(u16)(arr)
}

tokenizer_read_bpe :: proc(filename: string) -> Tokenizer {
  file, file_ok := os.read_entire_file(filename, context.allocator)
	ensure(file_ok)

  table_len := int(bytes_to_u32(file[0:4]))
  tokens_len := int(bytes_to_u32(file[4:8]))

  tokenizer := Tokenizer{
    make([dynamic]Token, 0, tokens_len),
    make([dynamic]Pair, 0, table_len),
  }

  ofs := 8
  tkn_size := size_of(Token)
  for i := ofs; i < table_len * tkn_size * 2 + ofs; i+=(tkn_size*2) {
    token := Pair{
      bytes_to_u16(file[i:i+tkn_size]),
      bytes_to_u16(file[i+tkn_size:i+tkn_size*2]),
    }
    append(&tokenizer.table, token) 
  }

  ofs += table_len * tkn_size * 2
  for i := ofs; i < tokens_len * tkn_size + ofs; i+=tkn_size {
    append(&tokenizer.tokens, bytes_to_u16(file[i:i+tkn_size])) 
  }

  return tokenizer
}
