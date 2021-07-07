# lhs2TeX-Build

A tool to build multi-file LaTeX projects that also need lhs2tex.

## Usage

Create a `.tex-build` file, then run `lhs2tex-build` in the root directory.

## Installation

1. Install lhs2TeX: `cabal install lhs2tex`

2. Install TeX Live: https://www.tug.org/texlive/acquire-netinstall.html

3. Clone lhs2TeX-build 

4. Install lhs2TeX-build: `cd lhs2tex-build && cabal install`


## Example

Here is a simple example of how to use the build tool.

### .tex-build File

Create a `.tex-build` file, for example `dissertation.tex-build`:

``` yaml
mainFile: dissertation.lhs
outputName: dissertation
lhsFiles: [dissertation.lhs
         , chapters/introduction.lhs
         , chapters/background.lhs
         , chapters/the-language.lhs
         , chapters/implementation.lhs
         , chapters/benchmarks.lhs
         , chapters/examples.lhs
         , chapters/conclusion.lhs]
```

### Including files

To include files in the LaTeX document, use the `subfiles` package along with the `\subfileinclude` command.
