# Date: 2016-05-28; Title: Having Fun with Computation Expressions; Tags: fsharp,computation,expression,delay; Author: Matthias Dittrich

Or how I build a generic computation builder library.

Over the last days I build a F# API for google music by using [gmusicapi](https://github.com/simon-weber/gmusicapi) and [pythonnet](https://github.com/pythonnet/pythonnet/) (two awesome projects by the way).
The Python C-API requires you to request the `GIL` (Global Interpreter Lock) before you can safely use the API.
Because I knew I would forget to do this all over the place I decided to mark those places explicitly with the help of
computation expressions. Doing this on a low level means I can safely use it on higher levels. 

I decided to build the computation expression like [this](https://github.com/matthid/googleMusicAllAccess/blob/e6713d3662162f10ab9d9b3d76e71609b9209a25/src/GMusicApi/PythonInterop.fs#L23):

```fsharp
type PythonData<'a> =
  private { 
    Delayed : (unit -> 'a)
    mutable Cache : 'a option
  }
let pythonFunc f = { Delayed = f; Cache = None }
let internal unsafeExecute (f:PythonData<_>) =
  match f.Cache with
  | Some d -> d
  | None ->
    let res = f.Delayed()
    f.Cache <- Some res
    res
let private getPythonData = unsafeExecute
let runInPython f = 
  use __ = Python.Runtime.Py.GIL()
  f |> getPythonData
```

The builder is straightforward from there (see link above).

Of course now we need to interact with sequences and er need something like [FSharp.Control.AsyncSeq](https://github.com/fsprojects/FSharp.Control.AsyncSeq).
Basically all I had to do was copy the code from there and replace the builder.

Wait... What? We will look into this later.

Now I got really curious, I really only want to replace the 'runInPython' function and there is nothing specific 
about my python problem in the builders. Can we be more generic here? Just adding more `run` functions is not
really practical as then users can just use the wrong one...

Let the fun begin... Lets first start with a general purpose `delayed` builder and lets see what we can do from there:

```fsharp

type Delayed<'a> =
  private { 
    Delayed : (unit -> 'a)
    mutable Cache : 'a option
  } 
  
module Delayed =
  let create f = { Delayed = f; Cache = None }
  let execute (f:Delayed<_>) =
    match f.Cache with
    | Some d -> d
    | None ->
      let res = f.Delayed()
      f.Cache <- Some res
      res
      
  let map f d =
    (fun () -> f (d |> execute)) |> create

type ConcreteDelayedBuilder() =
	let create f = Delayed.create f
	let execute e = Delayed.execute e
	member x.Bind(d, f) =
		(fun () -> 
			let r = d |> execute
			f r |> execute
			) |> create

	member x.Return(d) = 
		(fun () -> d) |> create
	member x.ReturnFrom (d) = d
	member x.Delay (f) = 
		(fun () -> f() |> execute) |> create
	member x.Combine (v, next) = x.Bind(v, fun () -> next)
	member x.Run (f) = f
	member x.Zero () = (fun () -> ()) |> create
	member x.TryWith (d, recover) =
		(fun () -> 
		try
			d |> execute
		with e -> recover e |> execute) |> create
	member x.TryFinally (d, final) =
		(fun () -> 
		try
			d |> execute
		finally final ()) |> create
	member x.While (condF, body) =
		(fun () -> 
		while condF() do
			body |> execute) |> create
	member x.Using (var, block) =
		(fun () -> 
		use v = var
		block v |> execute) |> create
	member x.For (seq, action) = 
		(fun () -> 
		for item in seq do
			action item |> execute) |> create

let delayed = ConcreteDelayedBuilder()
```

Ok looks good: We have a simple `delayed` builder. 
What we want now is some kind of converter to convert this `Delayed<'T>' in a `PythonData<'T>`

I would design the type like this:

```fsharp
  type PythonData<'T> = private { D : Delayed<'T> }
  let runInPython f = 
    use __ = Python.Runtime.Py.GIL()
    f.D |> Delayed.execute
```

Therefore callers cannot use the underlying `Delayed` object. 
But how do we generically get a computation builder and how would the result look like?

We would like to build a generic (computation expression builder) type with some kind of converter parameter which itself calls the regular `delayed` builder.
```fsharp
type IDelayedConverter<'b> =
	member ToDelayed : 'b<'a> -> Delayed<'a>
	member OfDelayed : Delayed<'a> -> 'b<'a>
```

Something like this is what we want, but sadly this is not possible (see [uservoice](https://visualstudio.uservoice.com/forums/121579-visual-studio-2015/suggestions/2228766-add-higher-order-generics-to-f-type-classes)).
Can we work around this limitation?
I decided to use a interface with marker classes for this. If you have a better idea let me know!

```fsharp
type IDelayed<'b, 'a> = interface end
type DefaultMarker = class end 
type Delayed<'a> =
  private { 
    Delayed : (unit -> 'a)
    mutable Cache : 'a option
  } with
  interface IDelayed<DefaultMarker, 'a>

/// Ideally we want 'b to be a type constructor and return 'b<'a>...
type IDelayedConverter<'b> =
  abstract ToDelayed : IDelayed<'b, 'a> -> Delayed<'a>
  abstract OfDelayed : Delayed<'a> -> IDelayed<'b, 'a>
```

Now we can change our computation builder to take an instance of a converter:

```fsharp
type ConcreteDelayedBuilder<'b>(conv : IDelayedConverter<'b>) =
    let execute a = a |> conv.ToDelayed |> Delayed.execute
    let create f = f |> Delayed.create |> conv.OfDelayed

	// .. Continue with the old code.
```

Which leads to our default instance like this:

```fsharp
  // Add to the Delayed module...
  let conv =
    { new IDelayedConverter<DefaultMarker> with
       member x.ToDelayed p = (p :?> Delayed<'a>)
       member x.OfDelayed d = d :> IDelayed<DefaultMarker, _> }


[<AutoOpen>]
module DelayedExtensions =
  
  let delayed = ConcreteDelayedBuilder(Delayed.conv)

```

Nice! Now we can create the python builder like this:

```fsharp
module Python =
  type PythonDataMarker = class end 
  type PythonData<'T> = private { D : Delayed<'T> } with
    interface IDelayed<PythonDataMarker, 'T>
  let internal pythonConv =
    { new IDelayedConverter<PythonDataMarker> with
       member x.ToDelayed p = (p :?> PythonData<'a>).D
       member x.OfDelayed d = { D = d } :> IDelayed<PythonDataMarker, _> }
  let runInPython f = 
    use __ = Python.Runtime.Py.GIL()
    pythonConv.ToDelayed f |> Delayed.execute
  
  let python = ConcreteDelayedBuilder(pythonConv)
```

A bit of setup but wow we `almost` made it. What we now want is the `pythonSeq` or `delayedSeq` computation builder.
When we think about it we want a generic builder which takes the regular builder as parameter.

Oh that sounds like it will create a bunch of problems, but lets start to convert the AsyncSeq code. 
In theory all we need to do now is copy the AsyncSeq code and replace 

 - `AsyncSeq<'T> -> DelayedSeq<'b, 'T>`
 - `IAsyncEnumerator<'T> -> IDelayedEnumerator<'b, 'T>`
 - Potentially add some type paramters to the helper classes.
 - replace the `async` builder with our parameter `builder`
 - `Async<'T> -> IDelayed<'b, 'T>`

First problem: We cannot use modules to define our functionality because we actually have a parameter (the underlying builder).

So lets start with the interfaces

```fsharp
type IDelayedEnumerator<'b, 'T> =
  abstract MoveNext : unit -> IDelayed<'b, 'T option>
  inherit System.IDisposable

type IDelayedEnumerable<'b, 'T> =
  abstract GetEnumerator : unit -> IDelayedEnumerator<'b, 'T>

type DelayedSeq<'b, 'T> = IDelayedEnumerable<'b, 'T>
```

This will do. 


Lets start with `empty` (from [here](https://github.com/fsprojects/FSharp.Control.AsyncSeq/blob/master/src/FSharp.Control.AsyncSeq/AsyncSeq.fs#L97)):

```fsharp
type DelayedSeqBuilder<'b>(builder : ConcreteDelayedBuilder<'b>) =
  //[<GeneralizableValue>]
  member x.empty<'T> () : DelayedSeq<'b, 'T> = 
        { new IDelayedEnumerable<'b, 'T> with 
              member x.GetEnumerator() = 
                  { new IDelayedEnumerator<'b, 'T> with 
                        member x.MoveNext() = builder { return None }
                        member x.Dispose() = () } }
 
```

Ok, it actually compiles. This is a good step forward. There we go: A computation builder as a parameter.
The next special thing happens when they define helper types within their module. We cannot do this in a type.
Therefore we will just move all the helpers above the `DelayedSeqBuilder<'b>` type and mark them as internal ([see here](https://github.com/matthid/DelayComputationExpression/blob/master/src/DelayComputationExpression/DelayedSeq.fs#L13)).

Why did I name this type `DelayedSeqBuilder<'b>` and not like the corresponsing module?
Because we cannot define the computation builder inside. Instead we will define all the functions here as members.
This will later make the following possible:

```fsharp
  let seq =
    pythonSeq {
      for i in [1, 2, 3] do
        // Call Python API
        let! t = tf
        yield t + "test"
    }

  let first =
    seq
    |> pythonSeq.firstOrDefault "default"
```

But we are not there yet. So instead of defining the AsyncSeqBuilder inside the module we will just define everything in the builder itself.
We are now [here in AsyncSeq](https://github.com/fsprojects/FSharp.Control.AsyncSeq/blob/master/src/FSharp.Control.AsyncSeq/AsyncSeq.fs#L211), or [here with the port](https://github.com/matthid/DelayComputationExpression/blob/master/src/DelayComputationExpression/DelayedSeq.fs#L162).

Now they do something which is not good for us. They define `asyncSeq` inside the module to define the higher level functionality as extension methods later.
One example is the `emitEnumerator` function. We cannot create an instance, because we don't know the paramter.
But wait we already have an `this` (`x`) reference to ourself. What if we use that?

```fsharp
  member x.emitEnumerator (ie: IDelayedEnumerator<'b, 'T>) = x {
      let! moven = ie.MoveNext() 
      let b = ref moven 
      while b.Value.IsSome do
          yield b.Value.Value 
          let! moven = ie.MoveNext() 
          b := moven }
```

And again it compiles! This is crasy. With this (!) we can easily port the rest of the functionality.

Now we just need to extend the regular builder with the async for. But this is straightforward as well:

```fsharp
[<AutoOpen>]
module DelayedSeqExtensions =
  // Add asynchronous for loop to the 'async' computation builder
  type ConcreteDelayedBuilder<'b> with
    member internal x.For (seq:DelayedSeq<'b, 'T>, action:'T -> IDelayed<'b, unit>) =
      let seqBuilder = DelayedSeqBuilder(x)
      seq |> seqBuilder.iterDelayedData action 
```

We can define the final functionality by using both builders. But wait there is one more problem.
When we define extension methods for the `DelayedSeqBuilder<'b>` type we cannot access the underlying builder parameter anymore.
So lets add a property to access it:

```fsharp
type DelayedSeqBuilder<'b>(builder : ConcreteDelayedBuilder<'b>) =
  // ... 
  member x.Builder = builder
// ...
[<AutoOpen>]
module DelayedSeqExtensions =
  // ...
  type DelayedSeqBuilder<'b> with
    member x.tryLast (source : DelayedSeq<'b, 'T>) = x.Builder { 
        use ie = source.GetEnumerator() 
        let! v = ie.MoveNext()
        let b = ref v
        let res = ref None
        while b.Value.IsSome do
            res := b.Value
            let! moven = ie.MoveNext()
            b := moven
        return res.Value }
```

And we can finaly create the computation builder instances:

```fsharp
  let delayedSeq = new DelayedSeqBuilder<_>(delayed)
```

And for our python use case:

```fsharp
  let python = ConcreteDelayedBuilder(pythonConv)
  let pythonSeq = DelayedSeqBuilder(python)
```

What have we done here:

 - We created a library to create your own computation builders with minimal amount of code (by providing an interface implementation)
 - We worked around F# not supporting high order generics
 - We used a computation builder as parameter
 - We used the `this` reference as computation builder
 - We used a property as computation builder

It's really sad that we cannot define the DelayedSeqBuilder more generically.
I'm pretty sure that would be usable for some exting computation builders as well.
Maybe there is something we can do with type providers here ;).

This is all for now :). You can use this in your code via [nuget](https://www.nuget.org/packages/DelayComputationExpression).
Of course the code is on [github](https://github.com/matthid/DelayComputationExpression).
