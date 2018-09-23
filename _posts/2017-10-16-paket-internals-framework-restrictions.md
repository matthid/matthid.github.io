---
layout: post
title: "Paket internals - Framework Restrictions"
---

## Intro

> Warning: This is a quite technically detailed article (besides some introduction). 
> If you search for a paket intro there is a perfect up to date blog-series by Isaac:
> 
> - [Part1 - Getting started with Paket](https://cockneycoder.wordpress.com/2017/08/07/getting-started-with-paket-part-1/)
> - [Part2 - Convert from NuGet basics](https://cockneycoder.wordpress.com/2017/08/14/migration-basics-from-nuget-to-paket/)
> - [Part3 - Convert from NuGet advanced](https://cockneycoder.wordpress.com/2017/08/21/migrating-complex-nuget-solutions-to-paket/)

There was a time I remember perfectly well when I thought that NuGet works perfectly fine. Additionally, I was already heavily contributing to `FSharp.Formatting` and from time to time to `FAKE`, so how could I use just another tool which might need some attention?

![Paket Contributions](/public/images/blog/2017-10-16/paket_contributions.png "paket")
![FSharp.Formatting Contributions](/public/images/blog/2017-10-16/fsf_contributions.png "fsf")

Why would you contribute to a project when you still use the alternative?
Well, time has changed - after wasting enough time with NuGet updates and other shortcomings I'm now a happy Paket user and contributor for quite some time now. 

## Why not "new" NuGet?

Personally, some things need to change before I even consider using NuGet again:

 - `git diff` needs to show which versions (including transitive packages) changed: This is a very good feature of Paket and helped several times to debug and find complicated version conflicts.
 - `restore` needs to restore exact version OR fail, nothing in between: How can you debug complicated conflicts when the versions you get are random?
 - `update` needs to update my transitive packages as far as they are allowed by the corresponding version constraints: Otherwise I always need to specify all transitives myself to get bugfixes - in no way better than `packages.config`

As you can see there is no point in going back - even after they redesigned their whole system.

## Paket internals

Now let's see how it works!

> Warning2: Some internals are very hard to understand or to get right. So this post doesn't demand correctness or completness.

## Update

Update is the process of resolving your `paket.dependencies` file to an `paket.lock` file in a fully automated manner. This process happens in several steps:

- Parse the `paket.dependencies` file
- Find a solution for the dependencies riddle
- Write `paket.lock`
- Download and extract the packages
- Analyse the package contents and figure out "relevant" files
- Edit project files according to `paket.references` (internally called "Install")
- Show the final Report

Some of this stuff is pretty "primitive" and I will not look into it a lot (parsing, writing and extracting for example) other things like finding the solution have become so complex that I only understand parts of it.

### Datastructures and Resolving (overview)

#### Framework restrictions

Because it helps understanding the resolver and makes explaining it a lot easier we start with a quite (if not the most) important concept in Paket: A framework restriction.

Let's first go briefly to the terminology (from Paket's view):

 - framework identifier: Basically everything besides portables
 - target profile or profile or platform: Either a framework identifier to represent a single platform or a list of identifiers to represent a portable profile.
 - framework (without identifier) often used as synonym for profile
 - tfm (target framework moniker) a string identifier specified by NuGet for a particular platform. Basically, "target profile" = "tfm"

It is a bit problematic that we (the paket developers) don't always use exactly defined terms due to historical reasons - often you get the exact meaning only by context.


Now, you need to understand that the NuGet ecosystem provides packages for a lot of existing platforms. Those platforms are documented [here](https://docs.microsoft.com/en-us/nuget/schema/target-frameworks). Therefore I simplified the `FrameworkIdentifier` type definition from the [real one](https://github.com/fsprojects/Paket/blob/master/src/Paket.Core/Versioning/FrameworkHandling.fs#L12-L470):

> Generally I will simplify type definitions to make the point more clear. Often we store additional data in such datastructures for performance or UX reasons (for example to provide better warnings/errors at certain places).

```fsharp
type FrameworkIdentifier =
    | Net45
    | Net46
    //| ... lots of others

type TargetProfile =
    | SinglePlatform of FrameworkIdentifier
    | PortableProfile of FrameworkIdentifier list


type FrameworkRestrictionP =
    private
    | ExactlyP of TargetProfile
    | AtLeastP of TargetProfile
    // Means: Take all frameworks NOT given by the restriction
    | NotP of FrameworkRestrictionP
    | OrP of FrameworkRestrictionP list
    | AndP of FrameworkRestrictionP list
type FrameworkRestrictionLiteralI =
    | ExactlyL of TargetProfile
    | AtLeastL of TargetProfile
type FrameworkRestrictionLiteral =
    { LiteraL : FrameworkRestrictionLiteralI; IsNegated : bool }
type FrameworkRestrictionAndList =
    { Literals : FrameworkRestrictionLiteral list }
type FrameworkRestriction =
    private { OrFormulas : FrameworkRestrictionAndList list }
type FrameworkRestrictions =
    | ExplicitRestriction of FrameworkRestriction
    | AutoDetectFramework

```

So in simple words a framework restriction is a general formula which describes a set of `TargetProfile` in [DNF](https://en.wikipedia.org/wiki/Disjunctive_normal_form). We decided to use DNF because in our domain they tend to be shorter and keeping them in DNF throughout the applications allows us to simplify formulas along the way with [simple algorithms](https://github.com/fsprojects/Paket/blob/73664a750b8c0b1ac4cf6ed795f72c4e1380e9d3/src/Paket.Core/Versioning/Requirements.fs#L301-L448). Example of such formulas are `>= net45` or `OR (>= net45) (<netcoreapp1.0)`.

As briefly described above, each formula represents a set of profiles and this set is defined like this:

```fsharp
    member x.RepresentedFrameworks =
        match x with
        | FrameworkRestrictionP.ExactlyP r -> [ r ] |> Set.ofList
        | FrameworkRestrictionP.AtLeastP r -> r.PlatformsSupporting
        | FrameworkRestrictionP.NotP(fr) ->
            let notTaken = fr.RepresentedFrameworks
            Set.difference KnownTargetProfiles.AllProfiles notTaken
        | FrameworkRestrictionP.OrP (frl) ->
            frl
            |> Seq.map (fun fr -> fr.RepresentedFrameworks)
            |> Set.unionMany
        | FrameworkRestrictionP.AndP (frl) ->
            match frl with
            | h :: _ ->
                frl
                |> Seq.map (fun fr -> fr.RepresentedFrameworks)
                |> Set.intersectMany
            | [] -> 
                KnownTargetProfiles.AllProfiles
```

Basically "AtLeast" (`>=`) means "all profiles which are supporting the current profile". "Supporting" in that sense means that if I have two profiles `X` and `Y` and create a new project targeting `Y` and I can reference packages with binaries build against `X` we say `Y` supports `X`. For example `net46` supports `net45` therefore `net46` is part of the set `>= net45`. Some further examples:

 - `net47` is in `>= netstandard10`
 - `netcoreapp10` is in `>= netstandard16`
 - `net45` is in `< netstandard12` which is equivalent to `NOT (>= netstandard12)`, because `net45` is NOT in `>= netstandard12`
 - `net45` is NOT in `< netstandard13`

It is confusing, even for me, who wrote this stuff. The important thing here is to get away from the thinking of "smaller" and "higher" because it has no real meaning. On the other hand "supports" has a well defined meaning.
Also don't try to give `< tfm` any meaning besides a particular set of frameworks. This makes reasoning a lot simpler (just see it as an intermediate value used for simplifications and calculations).
Technically, you could see it as "all platforms not supporting a particular tfm".

So, now we know that a framework restriction is a formula which represents a particular list of frameworks (which we can now calculate given the NuGet documentation from above). But why do we need them?

The answer is the resolver phase. Let's compare with plain NuGet: In NuGet you have a project targeting a single platform. NuGet now goes hunting for compatible packages for this particular platform. So at resolution time it knows which dependencies to take and what files it needs to install from a package.
You might say: But what about new NuGet? The answer is the principle is not different at all. In the new world they resolve for each platform separatly exactly as described. This - in addition to how they resolve package versions -  makes the resolution phase dead simple.

Paket on the other hand has a different world view. We assume the following to be true:

 - Packages properly define their dependencies (Note: NuGet explicitely assumes the reverse)
 - You want to reach a unified view of your dependencies-tree. This means you accept different packages for different platforms but you only accept a single version of a package supporting all your target profiles.

This means we tell our resolver our acceptable range of dependencies and the list of frameworks (see what I did there?) we want to build for. Obviously in practice we use framework restrictions for this:

```fsharp

type PackageName = string
type SemVerInfo = string
type VersionRangeBound =
    | Excluding
    | Including
type VersionRange =
    | Minimum of SemVerInfo
    | GreaterThan of SemVerInfo
    | Maximum of SemVerInfo
    | LessThan of SemVerInfo
    | Specific of SemVerInfo
    | OverrideAll of SemVerInfo
    | Range of fromB : VersionRangeBound * from : SemVerInfo * _to : SemVerInfo * _toB : VersionRangeBound
type VersionRequirement = VersionRange

type InstallSettings = 
    { FrameworkRestrictions: FrameworkRestrictions }

type PackageRequirementSource =
| DependenciesFile of string
| Package of PackageName * SemVerInfo * PackageSource

type PackageRequirement =
    { Name : PackageName
      VersionRequirement : VersionRequirement
      Parent: PackageRequirementSource
      Graph: PackageRequirement Set
      Sources: PackageSource list
      Settings: InstallSettings }

type DependencySet = Set<PackageName * VersionRequirement * FrameworkRestrictions>

type ResolvedPackage = {
    Name                : PackageName
    Version             : SemVerInfo
    Dependencies        : DependencySet
    Unlisted            : bool
    IsRuntimeDependency : bool
    IsCliTool           : bool
    Settings            : InstallSettings
    Source              : PackageSource
} 

val Resolve : Set<PackageRequirement> -> Map<PackageName, ResolvedPackage>
```

As you can see we input a set of `PackageRequirement` where every requirement contains framework restrictions in its settings.

But what do we get? The answer is that we not only need to know the version and the name of a particular package but also on which list of frameworks we are having this dependency. Again this is part of the settings of the result.

Need an example? Consider package `A`:

- For `tfm-b` it depends on `B` in version 1.0 
- For `tfm-c` it depends on `C` in version 1.0

These conditions are called "dependency groups". Here we have two dependency groups, one for `tfm-b` and one for `tfm-c`

Now if we put into the resolver that we want to depend on `A` and build for all frameworks (= have no framework restrictions, note in this simplified scenario I could say we use the list `OR (= tfm-b) (= tfm-c)` - see framework restrictions are lists ;)).
What do we want as result?

Well, we want Paket to tell us that `B` needs to be installed but only for the list of frameworks `>= tfm-b` and `C` for the list of frameworks `>= tfm-c`! Can you spot the error?

The error is that the answer is wrong and the correct one depends on how `tfm-b` and `tfm-c` relate to each other!

For example consider `tfm-b` supports `tfm-c` which means `tfm-b` is in `>= tfm-c`. Then the correct answer is that we need to install `B` for  `>= tfm-b` and `C` for `AND (>= tfm-c) (< tfm-b)`. (Think of `tfm-b = net45` and `tfm-c = net40`). The reason for this is that we should always decide for a single "dependency group".

Another interesting case is when they don't directly relate to each other (ie none is supported by the other) but `AND (>= tfm-c) (>= tfm-b)` is not the empty set. For example consider `tfm-c = netstandard10` and `tfm-b = net35`. Now the correct answer is kind of difficult. Because for the set `AND (>= tfm-c) (>= tfm-b)` there is no good answer. What paket does is it reuses it's internal cost function to figure out if a random member of the `AND` set matches better to `tfm-c` or `tfm-b` and then assigns the remaining items to the result. Lets assume the missing list matches "better" to `tfm-c` then we get:

 - Install `C` when `OR (>= tfm-c) (AND (>= tfm-c) (>= tfm-b))` which will be simplified to `>= tfm-c`
 - Install `B` when `AND (>= tfm-b) (< tfm-c)`.

The above logic is encoded in [this 51 line function](https://github.com/fsprojects/Paket/blob/73664a750b8c0b1ac4cf6ed795f72c4e1380e9d3/src/Paket.Core/Versioning/Requirements.fs#L989-L1040) which probably needs a bit time to read (it took quite a bit time to write "correctly", so that's probably fair).

> Just when writing this blog post I noticed that there is a bug in the above logic. Please send a PR if you can figure out what the problem is ;)

Ok this is enough for now, more internals might follow...

Please ping me on [twitter](https://twitter.com/matthi__d) to tell me what you want to know next. Or open an issue on Paket :)