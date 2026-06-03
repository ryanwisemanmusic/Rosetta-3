This folder owns the 16-bit DOS execution layer for Rosetta 3.

The goal here is to build a reusable real-mode foundation rather than title-
specific behavior:

- 8086/real-mode CPU state
- 20-bit segmented memory
- DOS/BIOS interrupt handling
- COM/MZ-style load state
- host I/O bridging for text-mode execution
- source/binary bridges that can grow into fuller 16-bit execution

The current runtime is intentionally conservative: it establishes the pieces
that DOS titles need before they can execute correctly, especially segmented
addressing and interrupt-driven text/input behavior. This namespace should own
those concerns instead of pushing them into generic x86 or app-specific code.
