# Terminology and Concepts

## Pieces

ECell systems are built out of services called **Pieces**. Generally speaking,
Pieces will correspond one-to-one with Ruby processes. Pieces communicate with
each other over ØMQ sockets. To run a Piece, make an instance of
`ECell::Runner` and call its `run!` method with a configuration hash.

A fragment of a Piece configuration hash that contains everything except
deployment-specific settings (e.g., which IP to bind to) may be referred to as
a **Sketch**.

## Figures

A Piece is composed of a cooperating group of actors called **Figures**. Each
Figure is an instance of some subclass of `ECell::Elements::Figure`. These
subclasses are referred to as **Shapes**. Figures may implement some sort of
functionality used by other Figures in the Piece, such as making RPCs, or they
may implement logic specific to the Piece they're in, such as serving a
specific website.

It is common for there to be certain features in a mesh that involve
functionality in Figures in more than one Piece; the aforementioned example of
RPCs would require both calling functionality in a Figure in the calling Piece
and responding functionality in a Figure in the responding Piece. In this case,
there should only be one Shape, corresponding to the entire multi-Piece
functionality, which both Figures instantiate. The separate Piece-level
functionalities should be implemented in separate modules under the Shape. Such
modules are called **Faces**.

The current naming convention is that Shape names should be nouns describing
the multi-Piece functionality they provide, and Face names should be verbs
describing the actions that they allow a Figure to perform. This applies
primarily to Shapes intended for use in multiple Pieces; Shapes that implement
Piece-specific logic have no particular convention.

## Lines

Connections between Pieces are referred to in the abstract as **Lines**. The
term Line is also used to refer to instances of the class
`ECell::Elements::Line`, which wrap ØMQ sockets. Subclasses of `Line` are
referred to as **Strokes**, and generally correspond to specific types of ØMQ
socket.

## Designs

A list of Figures and Lines to spawn that jointly serve some specific purpose
in a Piece is called a **Design**. A Piece configuration hash contains, among
other things, a list of Designs to use.

## Color

`ECell::Elements::Color` is a class whose instances are a bit like fancy
hashes. They're used all over ECell as generic data objects. Messages between
Pieces are generally represented as instances of `Color`. Each instance is
tagged with a symbol indicating its "form". This symbol should also be a valid
key in the object.

