# Generating ROSE Code from RISC-V SAIL

This README file describes the end-to-end pipeline for generating ROSE C++ instruction semantics from the official RISC-V formal specification written in SAIL. The pipeline consists of two stages:

1. **SAIL → JSON**: An OCaml-based frontend parses the SAIL semantics and emits a simplified JSON representation.
2. **JSON → ROSE**: A Perl-based source-to-source compiler translates the JSON semantics into ROSE C++ code.

The focus of this document is on how to build and run each stage, and how to extend the pipeline for new instruction sets or extensions.

## Overview of the Pipeline

```
SAIL (.sail files)
   ↓
OCaml SAIL parser (JSON backend)
   ↓
JSON semantics
   ↓
Perl JSON-to-ROSE compiler
   ↓
ROSE C++ instruction semantics
```

## Stage 1: SAIL to JSON

### SAIL JSON Backend

This backend parses SAIL semantics and emits a JSON representation of functions (in particular, instruction `execute` functions), which is later consumed by the ROSE generator. The current JSON backend is based on sail 0.20.

### Required Dependencies

To build the SAIL toolchain with the JSON backend, the following dependencies are required:

* `libgmp-dev`
* `z3`
* `pkg-config`

#### Ubuntu

```bash
sudo apt-get install build-essential libgmp-dev z3 pkg-config
```

#### macOS (Homebrew)

```bash
brew install gmp z3 pkgconf
```

### OCaml Version Requirement

The parser requires **OCaml ≥ 4.08.1**. If your system OCaml is older, create a newer switch using Opam:

```bash
opam switch create 5.1.0
eval $(opam config env)
```

### Add JSON backend to SAIL

To add support for emitting JSON representation of SAIL, clone the SAIL repository from <https://github.com/rems-project/sail/> and checking out the correct version. The RISC-V SAIL model (v0.9) currently requires SAIL **version 0.20**, so make sure to switch to that tag explicitly:

```bash
git clone https://github.com/rems-project/sail/
cd sail
git switch -c v0.20 0.20
```

Next, update `dune-project` to register a new package for the JSON backend. Add the following line to `dune-project`:

```diff
     (base64 (>= 3.1.0))
     (omd (and (>= 1.3.1) (< 1.4.0)))))
+(package
+  (name sail_json_backend)
+  (synopsis "Sail to JSON translation")
+  (depends
+    (libsail (= :version))))
+
 (package
   (name sail)
   (synopsis "Sail is a language for describing the instruction semantics of processors")
```

Finally, copy the OPAM file and backend source directory into the SAIL repo:

```bash
cp path/to/dyninst-sail-to-rose/sail_json_backend.opam .
cp path/to/dyninst-sail-to-rose/sail_json_backend ./src
```

With these steps, the SAIL repo will include the JSON backend.

### Building the SAIL Parser

Once dependencies and the OCaml version are set up, install SAIL with the JSON backend:

```bash
opam install sail
```

After a successful build, the `sail` binary will be available in your Opam switch (or current directory). Verify the installation with:

```bash
sail --help
```

## Preparing the RISC-V SAIL Semantics

### Obtaining the RISC-V SAIL Model

The official RISC-V SAIL semantics are available at <https://github.com/riscv/sail-riscv>. Currently, **version 0.9** of the RISC-V SAIL model is supported. Check out this version explicitly:

```bash
git clone https://github.com/riscv/sail-riscv
cd sail-riscv
git switch -c v0.9 0.9
```

All relevant SAIL source files live under the `model/` directory.

### Linking the Model Directory

Change the directory back to `sail-to-json` and create symbolic link to the RISC-V model directory:

```bash
cd path/to/dyninst-sail-to-rose/sail-to-json
ln -s path/to/sail-riscv/model model
```

This allows the SAIL toolchain to locate the RISC-V semantics during parsing easily.

### SAIL Configuration File

RISC-V SAIL uses a JSON configuration file to select ISA profiles and extensions. A sample configuration for the `rv64gc` profile is provided in `config/rv64gc.json`

This file specifies:

* Base ISA and extensions
* Architectural parameters (e.g., XLEN)
* Miscellaneous platform information

To enable an extension (for example, the **Zicond** extension), change its `supported` field:

```json
"Zicond": {
  "supported": false
}
```

becomes:

```json
"Zicond": {
  "supported": true
}
```

### The `riscv.sail_project` File

The `riscv.sail_project` file defines how SAIL source files are grouped and built. Conceptually, it plays a role similar to a Makefile: it declares modules, dependencies, and configuration variables that are applied before typechecking and code generation.

A sample project file is located at `riscv.sail_project`. `sail_project` is made out of several `sail_project` blocks, which typically defines the following properties:

* Declares which Sail files belong to the project
* Defines the file path of the Sail files
* Sets dependencies for a specific extension
* Controls build ordering of source files

#### Adding a New Extension

To include a new extension like `Zicond`, add the following to `riscv.sail_project`:

```sail
Zicond {
  Zicond_types {
    before sys
    files extensions/Zicond/zicond_types.sail
  }
  Zicond_insts {
    requires sys, Zicond_types
    files extensions/Zicond/zicond_insts.sail
  }
}

```

### Generating the JSON Semantics

With the configuration in place, run SAIL with the JSON backend:

```bash
sail --config config/rv64gc.json \
     --no-warn \
     --strict-var \
     --json -O --Oconstant-fold \
     --all-modules \
     riscv.sail_project > sail_semantics.json
```

This produces `sail_semantics.json`, which contains the serialized semantics of all included instruction sets.

## Stage 2: JSON to ROSE

The second stage consumes `sail_semantics.json` and generates ROSE C++ code. This stage is implemented as a Perl-based source-to-source compiler.

In the RISC-V SAIL model, instruction semantics are grouped by **instruction sets** (not by extensions). Each instruction set defines an `execute` function, which is the entry point for semantic execution. The JSON representation of these `execute` functions is what the ROSE generator operates on.

### Install Dependencies

The following Perl modules are required for the parser:

* FindBin
* JSON
* Tie::IxHash

Install them using `cpan install`:

```bash
cpan install FindBin JSON Tie::IxHash
```

### Generating ROSE Code for an Instruction Set

For example, the `auipc` instruction belongs to the `UTYPE` instruction set. To generate its ROSE semantics:

```bash
perl json_to_rose.pl --insn-set=UTYPE
```

This extracts the `execute` function for `UTYPE` from the JSON file, builds an internal AST, and emits the corresponding ROSE C++ code.

```cpp
struct IP_UTYPE : P {
    void p(D d, Ops ops, I insn, A args, B raw) {
        SgAsmExpression *imm = args[1];
        SgAsmExpression *rd = args[0];
        enum Riscv64InstructionKind op = insn->get_kind();

        BaseSemantics::SValuePtr off;
        off = d->SignExtend(ops->shiftLeft(d->read(imm, 64, 0), ops->number_(64, 12)), 64);
        switch (op) {
            case rose_riscv64_op_lui: 
                d->write(rd, off);
                break;
            }
            case rose_riscv64_op_auipc: 
                d->write(rd, ops->add(PC, off));
                break;
            }
            default:
            assert(0);
                break;
        };
        return;
    }
};
```

## Structure of the JSON-to-ROSE Compiler

The Perl implementation is organized as follows:

* **`json_to_rose.pl`**: Entry point of the JSON-to-ROSE compiler
* **`ASTBuild.pm`**: Builds an internal AST from the JSON representation of SAIL functions
* **`ASTBuildFunc.pm`**: Delegates construction of complex function AST nodes to specialized handlers
* **`ASTBuildHelper.pm`**: Helper routines for AST construction
* **`ASTNode.pm`**: Definitions of internal AST nodes
* **`ASTType.pm`**: Type information for AST nodes
* **`ASTAdjust.pm`**: Post-processing and normalization of the AST
* **`PrintROSE.pm`**: Emits ROSE C++ code from the internal AST
* **`ParserCommon.pm`**: Shared utilities
* **`ParserConfig.pm`**: Configuration for instruction sets, argument mappings, and supported extensions

## Mapping SAIL Arguments to ROSE Arguments

SAIL and ROSE use different calling conventions for instruction semantics. Bridging this gap is handled in `ParserConfig.pm`.

### Example: `ITYPE`

In SAIL, the `ITYPE` instruction set is defined as:

```ocaml
function clause execute ITYPE(imm, rs1, rd, op) = {
  ...
}
```

In ROSE, the semantic function has the form:

```cpp
void p(D d, Ops ops, I insn, A args, B raw) {
  ...
}
```

ROSE passes instruction operands through `args`, in the same order returned by Capstone:

* `args[0]` → `rd`
* `args[1]` → `rs1`
* `args[2]` → `imm`

The SAIL `op` argument corresponds to the instruction kind, which can be obtained in ROSE via `insn->get_kind()`.

The mapping in `ParserConfig.pm` is therefore:

```perl
ITYPE => ordered_hash(
    imm => {
        init_code => sub {
            print_indent("SgAsmExpression *imm = args[2];\n", 2);
        },
        need_read => 1,
    },
    rs1 => {
        init_code => sub {
            print_indent("SgAsmExpression *rs1 = args[1];\n", 2);
        },
    },
    rd => {
        init_code => sub {
            print_indent("SgAsmExpression *rd = args[0];\n", 2);
        },
    },
    op => {
        init_code => sub {
            print_indent(
                "enum Riscv64InstructionKind op = insn->get_kind();\n",
                2
            );
        },
    },
),
```

### Example: Adding the `RORI` Instruction (B Extension)

1. Enable the `B` extension in the SAIL configuration file

```json
"B": {
  "supported": true
}
```

2. Add the `B` extension SAIL files to `riscv.sail_project`:

```sail
B {
  B_types {
    before sys
    files model/extensions/B/bext_types.sail
  }

  B_insts {
    requires sys, B_types

    Zba {
      files model/extensions/B/zba_insts.sail
    }
    Zbb {
      files model/extensions/B/zbb_insts.sail
    }
    Zbc {
      files model/extensions/B/zbc_insts.sail
    }
    Zbs {
      files model/extensions/B/zbs_insts.sail
    }
  }
}
```

3. Add `RORI` to the supported instruction set, as well as `Ext_B` to the supported extension in `ParserConfig.pm`:

```perl
...
our @supported_riscv_subsets = (
    "UTYPE", "BTYPE", ..., "RORI"
);
...
our @supported_riscv_exts = (
    "Ext_M", "Ext_A", ..., "Ext_B"
)
...
```

4. Locate the `execute` function of the `RORI` instruction from `extensions/B/zbb_insts.sail`:

```ocaml
function clause execute RORI(shamt, rs1, rd) = {
  let shamt = shamt[log2_xlen - 1 .. 0];
  X(rd) = X(rs1) >>> shamt;
  RETIRE_SUCCESS
}
```

This instruction takes three arguments: `shamt`, `rs1`, and `rd`.

Since Capstone does not currently support the B extension, we assume the following operand order:

* `args[0]` → `rd`
* `args[1]` → `rs1`
* `args[2]` → immediate (`shamt`)

The corresponding mapping in `ParserConfig.pm` is:

```perl
RORI => ordered_hash(
    shamt => {
        init_code => sub {
            print_indent("SgAsmExpression *imm = args[2];\n", 2);
        },
        need_read => 1,
    },
    rs1 => {
        init_code => sub {
            print_indent("SgAsmExpression *rs1 = args[1];\n", 2);
        },
    },
    rd => {
        init_code => sub {
            print_indent("SgAsmExpression *rd = args[0];\n", 2);
        },
    },
),
```

Add the above code to `%ARGS_PER_SUBSET`.

4. Once the mapping is defined, regenerate the ROSE code with:

```bash
perl json_to_rose.pl --insn-set=RORI
```

This produces the ROSE C++ semantics for the `RORI` instruction set.

```cpp
struct IP_RORI : P {
    void p(D d, Ops ops, I insn, A args, B raw) {
        SgAsmExpression *shamt = args[2];
        SgAsmExpression *rs1 = args[1];
        SgAsmExpression *rd = args[0];

        BaseSemantics::SValuePtr shamt;
        shamt = ops->extract(shamt, 0, 5);
        d->write(rd, ops->rotateRight(d->read(rs1, 64, 0), shamt));
        return;
    }
};
```
