# Ex3mer

[![Actions Status](https://github.com/luisgabrielroldan/ex3mer/workflows/Tests/badge.svg)](https://github.com/luisgabrielroldan/ex3mer/actions)

Ex3mer is a library for building streams from HTTP resources


*(THIS IS WORK IN PROGRESS)*

## Basic operation

#### Example for S3

```elixir
Ex3mer.S3.get_object("my-bucket", "path/to/object")
|> Ex3mer.stream!()
|> Enum.to_list()
```

#### Generic download

```elixir
Ex3mer.download(:get, "http://example.com/path/to/file.zip")
|> Ex3mer.stream!()
|> Enum.to_list()
```


## Events stream

`Ex3mer.stream!/2` returns a stream of event tuples:
  
```
  iex(1)> Ex3mer.download(:get, "http://example.com/path/to/file.zip") \
  ...(1)> |> Ex3mer.stream!() \
  ...(1)> |> Enum.to_list()
[
  status: 200,
  headers: [
    {"Date", "Sat, 17 Apr 2021 02:57:29 GMT"},
    {"Last-Modified", "Wed, 12 Sep 2018 23:16:15 GMT"},
    {"Accept-Ranges", "bytes"},
    {"Content-Type", "application/zip"},
    {"Content-Length", "1435"},
    {"Server", "AmazonS3"}
  ],
  chunk: <<80, 75, 3, 4, 10, 0, 0, 0, 0, 0, 73, 189, 41, 77, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 6, 0, 28, 0, 102, 105, 108, 101, 115, 47, 85, 84, 9, 0, 3,
    218, 175, 149, 91, 178, 156, ...>>,
  chunk: <<32, 205, 24, 214, 136, 89, 42, 235, 113, 172, 7, 27, 1, 56, 0, 165,
    65, 169, 75, 214, 132, 130, 19, 114, 145, 110, 143, 129, 107, 54, 0, 40,
    204, 197, 64, 102, 206, 182, 95, 183, 30, 174, 73, 110, 126, 118, ...>>
]
```

The first two items emitted are the status and the response of headers.  The rest of the items are just chunks events.
In case of disconnection, a new request is made transparently but no status/header items are sent to the stream consumer.

## Data stream

`Ex3mer.stream_data!/2` returns a stream of chunks. If an error occurs an `%Ex3mer.Error{}` is raised.

```
  iex(1)> Ex3mer.Download.from(:get, "http://example.com/path/to/file.zip") \
  ...(1)> |> Ex3mer.stream_data!() \
  ...(1)> |> Enum.to_list()
[
  <<80, 75, 3, 4, 10, 0, 0, 0, 0, 0, 73, 189, 41, 77, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 6, 0, 28, 0, 102, 105, 108, 101, 115, 47, 85, 84, 9, 0, 3,
    218, 175, 149, 91, 178, 156, ...>>,
  <<32, 205, 24, 214, 136, 89, 42, 235, 113, 172, 7, 27, 1, 56, 0, 165,
    65, 169, 75, 214, 132, 130, 19, 114, 145, 110, 143, 129, 107, 54, 0, 40,
    204, 197, 64, 102, 206, 182, 95, 183, 30, 174, 73, 110, 126, 118, ...>>
]
```


