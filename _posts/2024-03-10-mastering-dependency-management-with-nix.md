---
layout: post
title: "Mastering Dependency Management with Nix in Machine Learning Projects"
---

Navigating the complexities of dependency management in large-scale machine learning projects can quickly become an overwhelming task. While traditional approaches offer some relief, they often fall short as project complexity increases, introducing inefficiencies that hinder development. This blog post is a chronicle of transitioning from conventional dependency management practices to adopting Nix, marking a significant shift towards simplifying and enhancing the development workflow.

## Intro

> Note: This journey into the world of Nix, supplemented by insights from AI tools including ChatGPT, captures my initial exploration into employing Nix for effective dependency management. I warmly welcome feedback and insights from the broader Nix community.

This guide is designed for incremental learning and application. You're encouraged to tackle it step-by-step, constructing your project from the outset to gain a thorough understanding of Nix's capabilities. However, the process is structured to support flexibility; feel free to pause at the end of any chapter and resume your journey later, picking up right where you left off. Whether you're experimenting with a single feature or ready to dive into the next chapter, the guide accommodates your pace.

For those who prefer to have a reference or need assistance troubleshooting, the accompanying GitHub repository, [nix-intro-examples](https://github.com/matthid/nix-intro-examples), includes the full project and all intermediate steps, captured through commits. This resource is intended as a supportive reference for comparison or if you encounter challenges while following the examples independently.

## From Chaos to Order

My initial approach to managing dependencies involved using Ubuntu-based Docker images, built on CUDA for GPU acceleration. This method, coupled with Anaconda or Miniconda for Python environment management, provided a semblance of control. However, it was far from foolproof. Custom-built packages, such as FFmpeg and OpenCV with CUDA support, often led to conflicting references between system and Conda environments, complicating the development workflow.

## Discovering Nix: A Turning Point

The shift to Nix emerged as a pivotal moment, driven by the quest for a more streamlined and manageable development environment. Nix's declarative nature promised an end to compatibility woes by ensuring precise and reproducible environments. Transitioning to Nix was not without challenges, particularly its steep learning curve. However, the payoff in dependency management efficiency was undeniable.

### Embarking on the Nix Journey

One of Nix's key advantages is its compatibility with virtually any existing distribution, making it an extremely versatile tool. You don't need to start with NixOS to benefit from Nix's powerful package management capabilities. This flexibility allows developers to maintain their current operating system environment while leveraging Nix to handle complex dependency graphs and ensure consistent, reproducible environments.

Let’s embark on our Nix journey with the initial setup:

```bash
# Install Nix (official)
sh <(curl -L https://nixos.org/nix/install) --daemon

# Verify the installation
nix-env --version
```

> Note: If you have a systems with enhanced security measures the official way might not work but the community has built an easy-to use installer for you [Determinate Nix Installer][2]

(Alternative, if the offical way fails)
```bash
# Install Nix (Determinate Nix Installer, works on systems with enhanced security, like fedora)
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install

# Verify the installation
nix-env --version
```

This installation script sets up Nix in a multi-user configuration, which is recommended for most use cases. After installation, you can immediately start using Nix to manage dependencies for your projects.

- For the official Nix installation guide, click [here][1].
- For the Determinate Systems installer for hardened systems, click [here][2].

[1]: https://nixos.org/download#download-nix
[2]: https://github.com/DeterminateSystems/nix-installer


## Basic Functionality

In this section, we'll cover the essentials to set up a project using Nix. The goal is to establish a development environment that ensures consistency and reproducibility, regardless of the underlying operating system. This involves creating a dedicated Nix folder within your project, adding `nix/shell.nix` and `nix/project.nix` configurations, and introducing a simple Python file to verify CUDA availability.

### Creating Your First Nix Shell

A Nix shell encapsulates your project's development environment, specifying all required dependencies, including tools and libraries. Here's how to create a `nix/shell.nix` file that includes Python 3, `touch`, `git`, and `curl`:

```nix
{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    pkgs.git
    pkgs.curl
  ];
}
```

This configuration ensures that these tools are available in your project's environment, enabling a consistent workflow across all development setups.

Now let's enter the shell: `nix-shell nix/shell.nix`

For discovering and incorporating official packages into your environment, the Nix package search at https://search.nixos.org/packages serves as an invaluable resource. As we progress, we'll also explore customizing and crafting our unique packages tailored to our project's specific needs.

### Transforming Your Project into a Library

To streamline dependency management and project packaging, it's efficient to structure your Python files as a library. This approach simplifies the process of packaging your project with Nix, making it more manageable and modular. By organizing your project as a library, you can leverage Nix's packaging capabilities to define dependencies explicitly and build your project in isolated environments.

### Kickstarting Your Project: The "Hello, World!" Example

To get started, let's create a simple Python project that outputs "Hello, World!". This example will help you familiarize yourself with the basic project structure and the process of integrating Nix.

1. **Project Structure**: Organize your project files under the `src/myproject` directory. Your main script, `hello.py`, will reside here, alongside the `__init__.py` file to treat this directory as a Python package.

2. **Hello, World! Script**: Create `hello.py` with the following content:

```python
# src/myproject/hello.py

def greet():
    print("Hello, World!")

if __name__ == "__main__":
    greet()
```

3. **Setup Script**: Add a `setup.py` file at the `src/` level to manage your project as a package:

```python
# src/setup.py
from setuptools import setup, find_packages

setup(
    name="myproject",
    version="0.1",
    packages=find_packages(),
)
```

4. **Initialization**: To ensure your `myproject` directory is recognized as a Python package, create an `__init__.py` file within it. Since we've included `touch` in our Nix shell environment, you can easily create this file using the following command:

```shell
[nix-shell]$ touch src/myproject/__init__.py
```

> Note: The use of `touch` here is seamless, thanks to its inclusion in our shell configuration!

This setup lays the groundwork for a Python project managed with Nix, setting the stage for further development and packaging.

To safeguard your project's progress and ensure version control from the get-go, let’s also initialize a Git repository. This step is straightforward in the Nix shell, even if Git isn't installed on your primary system:

```shell
[nix-shell]$ git init .
[nix-shell]$ git add -A
[nix-shell]$ git commit -m "Initial project setup"
```

> Note: This process works flawlessly within the Nix shell, showcasing another advantage of managing your development environment with Nix.

[Changes on GitHub](https://github.com/matthid/nix-intro-examples/commit/04f96f7ccf95959ca245bf416005d72abd72b034?diff=unified&w=1)

### Packaging Your Python Project with Nix

To effectively manage your Python project with Nix, start by creating a `nix/project.nix` file. This configuration specifies how to package your project, detailing its dependencies and build process. Utilizing Nix's `buildPythonPackage` from the `pythonPackages` collection simplifies defining your project's packaging requirements.

Below is a foundational example of a `nix/project.nix` file, illustrating how to structure it:

```nix
{ pkgs ? import <nixpkgs> {}
, python3Packages ? pkgs.python3Packages }:
let
  project_root = pkgs.lib.cleanSource ../.; # Cleans the parent directory for use
in
python3Packages.buildPythonPackage rec {
  pname = "myproject";
  version = "0.1";

  src = "${project_root}/src";
  pythonPath = [ "${project_root}/src" ];

  propagatedBuildInputs = [
    python3Packages.numpy # Example of a dependency
  ];

  # Disable or enable tests
  doCheck = false; # Set to true to enable test execution
  checkInputs = [ python3Packages.pytest ]; # Dependencies for running tests
  checkPhase = ''
    export PATH=${pkgs.lib.makeBinPath [ python3Packages.pytest ]}:$PATH
    cd ${project_root}/tests
    pytest
  '';
}
```

Key elements of this `nix/project.nix` file include:

- `pname` and `version` define the package's name and version.
- `src` designates the source code's location, using `${project_root}/src` to specify where the Python code resides.
- `propagatedBuildInputs` lists the project's dependencies, such as `numpy` in this example.
- `pythonPath` specifies the path to the Python modules, enabling Nix to locate your project's source code.
- `doCheck` toggles the execution of the project's test suite during the build. It's set to `false` by default but can be enabled as needed.
- The `checkPhase` outlines how to run the test suite, specifying the commands and dependencies required.

To test the packaging process and ensure everything is set up correctly, run:

```shell
[nix-shell]$ nix-build nix/project.nix
```

This command attempts to build your package according to the specifications in `nix/project.nix`. Successfully executing this command indicates that you have correctly packaged your first Nix-managed project. Next, let’s explore how to utilize this package effectively.

[Changes on GitHub](https://github.com/matthid/nix-intro-examples/commit/43945ad8b0a1d2fc2b5d883d5ba55a21834549fa?diff=unified&w=1)

### Integrating `nix/project.nix` into Your Development Environment

To seamlessly incorporate your package definition into the Nix development environment, reference `nix/project.nix` within your `nix/shell.nix`. This integration ensures that every time you enter the Nix shell, your project environment is automatically set up with all necessary dependencies. Modify your `nix/shell.nix` as shown below to include your project package:

```nix
{ pkgs ? import <nixpkgs> {} }:
let
  myProject = import ./nix/project.nix { pkgs = pkgs; };
in
pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    myProject
    pkgs.git
    pkgs.curl
  ];
}
```

This modification to `nix/shell.nix` effectively incorporates your Python project as a Nix package into your shell environment, simplifying the management of dependencies and streamlining project builds within a reproducible environment.

[Changes on GitHub](https://github.com/matthid/nix-intro-examples/commit/fac803fdcfe04eae4e71d7576cf02c6b2d882169?diff=unified&w=1)

### Activating Your Nix-Managed Environment

To activate and work within your newly defined Nix environment, you may first want to exit any existing shell sessions:

```shell
[nix-shell]$ exit # Optional, but cleanly exits the old shell
```

Then, initiate your Nix shell with the updated configuration:

```shell
$ nix-shell nix/shell.nix # Enter the shell with your project configurations
```

Once inside the Nix shell, you can run your Python script to verify that everything is set up correctly:

```shell
[nix-shell]$ python -m myproject.hello # Execute your script
```

This command runs the "Hello, World!" script we created earlier, demonstrating your project's successful integration into a Nix-managed development environment.

## Exploring Nix Syntax with `nix-repl`

To get a better grasp of Nix's syntax and how it operates, we'll use `nix repl`, a tool that lets you interactively experiment with Nix expressions. This practical approach will help you familiarize yourself with the basic constructs of Nix. Start `nix repl` by typing it into your nix-shell.

```shell
[nix-shell]$ nix repl
```

### Understanding `let ... in`

The `let ... in` expression allows you to define local variables within a Nix expression. These variables can then be used in the expression that follows the `in`.

**Example to Try in `nix-repl`**:
```nix
nix-repl> let a = 10; b = 20; in a + b
```
Copy and paste this into your `nix-repl`. This expression defines two variables, `a` and `b`, and calculates their sum.

### Unpacking Function Arguments: `{ ... }: ...`

Nix functions can accept arguments in a set, allowing you to unpack variables directly from the set.

**Example to Try in `nix-repl`**:
```nix
nix-repl> ( { name, value }: "Name: ${name}, Value: ${toString value}" ) { name = "Nix"; value = 42; }
```
This function takes a set with `name` and `value`, and returns a string incorporating both. The `toString` function is used to convert the integer `value` to a string.

### Default Values in Functions: `{ p ? ... }`

You can provide default values for function parameters within the `{ ... }` notation. If an argument isn't provided when the function is called, the default value is used.

**Example to Try in `nix-repl`**:
```nix
nix-repl> ( { text ? "Hello, Nix!" }: text ) {}
```
This function returns the default text because no argument is provided. Try modifying it to pass a different string:
```nix
nix-repl> ( { text ? "Hello, Nix!" }: text ) { text = "Learning Nix is fun!"; }
```

### Putting It All Together

You can combine these elements to create more complex expressions. Nix's functional nature allows you to build reusable, modular configurations.

**Composite Example to Try**:
```nix
nix-repl> let add = { x, y ? 1 }: x + y; in add { x = 5; }
```
This defines a simple function `add` that takes an argument `x` and an optional argument `y`, with a default value of `1`, then uses it to calculate a sum.

### Exploring Further with `nix-repl`

The `nix-repl` offers a rich set of commands beyond the basic examples we've explored. To discover these additional capabilities, simply type `:?` within the `nix-repl`. This command reveals a comprehensive list of options available to you, including loading and building Nix expressions from files, among other advanced debugging tools. While the examples provided give a solid foundation, don't hesitate to explore these more powerful features as you become more comfortable with Nix.

When you're ready to conclude your `nix-repl` session, exiting is straightforward. Simply type `:q` and press Enter. This command will gracefully close the `nix-repl`, returning you to your standard terminal prompt.

```shell
nix-repl> :?
nix-repl> :q
```

This exploration into the `nix-repl` is just the beginning of what's possible with Nix. As you grow more familiar with its syntax and capabilities, you'll find it an invaluable tool for managing complex dependencies and environments in a reproducible and declarative manner.

## Elevating Your Nix Skills: Incorporating CUDA and Docker

Delving into more advanced Nix functionalities opens up a world of possibilities for managing intricate project dependencies. This includes leveraging pre-built binaries like `torch-bin` for PyTorch with CUDA support and efficiently packaging your environment for Docker. These steps underscore Nix’s robustness in orchestrating elaborate environments effortlessly.

### Structuring Complex Dependencies

For projects requiring extensive dependency management, compartmentalizing these dependencies into a dedicated Nix file simplifies the process. Let’s focus on setting up `nix/dependencies.nix`. This file will utilize overlays to substitute the default `torch` package with `torch-bin`, optimizing resource usage during builds.

**Step 1: Define `nix/dependencies.nix`**

This configuration outlines an overlay to substitute PyTorch, enables proprietary packages, and activates CUDA support. Here’s a streamlined example:

```nix
{ pkgs ? import <nixpkgs> {
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
  }
, lib ? pkgs.lib
, my_python ? pkgs.python3
, cudatoolkit ? pkgs.cudaPackages.cudatoolkit
, }:
let
  python_packages = my_python.pkgs;
in {
  pkgs = pkgs;
  lib = lib;
  my_python = my_python;
  cudatoolkit = cudatoolkit;
  dependencies = with pkgs; [
    python_packages.numpy
    python_packages.torch-bin
    cudatoolkit
  ];
}
```

> **Note:** Enabling `allowUnfree` is necessary for incorporating proprietary software like CUDA. The `cudaSupport` flag globally empowers packages with CUDA capabilities, fostering a seamless integration.

**Step 2: Integrate Dependencies into Your Project**

Revise your `nix/project.nix` to leverage `nix/dependencies.nix`, ensuring a cohesive environment:

```nix
{ project_dependencies ? import ./dependencies.nix { }
, }:
let
  pkgs = project_dependencies.pkgs;
  lib = project_dependencies.lib;
  python_packages = project_dependencies.my_python.pkgs;
  project_root = pkgs.lib.cleanSource ../.; # Cleans the parent directory for use
in
python_packages.buildPythonPackage rec {
  pname = "myproject";
  version = "0.1";

  src = "${project_root}/src";
  pythonPath = [ "${project_root}/src" ];

  propagatedBuildInputs = project_dependencies.dependencies;

  # Disable or enable tests
  doCheck = false; # Set to true to enable test execution
  checkInputs = [ python_packages.pytest ]; # Dependencies for running tests
  checkPhase = ''
    export PATH=${pkgs.lib.makeBinPath [ python_packages.pytest ]}:$PATH
    cd ${project_root}/tests
    pytest
  '';
}
```

Verify the build integrity with:

```shell
[nix-shell]$ nix-build project.nix  # This may take some time for downloading and compiling.
```

**Step 3: Adjusting `shell.nix` for Dependency Integration**

To reflect your project's updated dependency management in your development environment, adapt your `shell.nix`. This modification aligns your Nix shell with the project's complex dependencies, ensuring consistency across development setups. For further reading on managing CUDA within Nix, consult the resources [here][3] and [here][4].

[3]: https://nixos.wiki/wiki/CUDA
[4]: https://sebastian-staffa.eu/posts/nvidia-docker-with-nix/

```nix
{ dependencies ? import ./dependencies.nix { } }:
let
  pkgs = dependencies.pkgs;
  myProject = import ./project.nix { project_dependencies = dependencies; };
in
pkgs.mkShell {
  buildInputs = [
    pkgs.python3
    myProject
    pkgs.git
    pkgs.curl
    pkgs.linuxPackages.nvidia_x11
    pkgs.ncurses5
  ];
  shellHook = ''
    export CUDA_PATH=${dependencies.cudatoolkit}
    export LD_LIBRARY_PATH=/usr/lib/wsl/lib:${pkgs.linuxPackages.nvidia_x11}/lib:${pkgs.ncurses5}/lib
    export EXTRA_LDFLAGS="-L/lib -L${pkgs.linuxPackages.nvidia_x11}/lib"
    export EXTRA_CCFLAGS="-I/usr/include"
  '';
}
```

**Step 4: Verifying CUDA Availability**

To confirm that CUDA is correctly configured in your project, update the `hello.py` script to include a check for CUDA availability. This test underscores the practical application of your Nix setup in a real-world scenario:

```python
# src/myproject/hello.py
import torch

def greet():
    print(f"Hello, World! Cuda available: {torch.cuda.is_available()}")

if __name__ == "__main__":
    greet()
```

Finally, to apply the recent changes and verify everything is in order, exit and re-enter your Nix shell. Then, run your updated Python script to see the results:

```shell
[nix-shell]$ exit
$ nix-shell nix/shell.nix
[nix-shell]$ python -m myproject.hello # Execute your script
Hello, World! Cuda available: True # Or False depending on your system
```

[Changes on GitHub](https://github.com/matthid/nix-intro-examples/commit/e010b57e00b94bdab445b5d7e13aff668523c581?diff=unified&w=1)


### Building Your First Docker Container with Nix

Incorporating Docker into your Nix-managed environment extends the reproducibility and portability of your setup. Drawing inspiration from a [practical guide on leveraging Nix with NVIDIA Docker][4], let's adapt the strategy to craft a Docker container for our project. The following configuration, saved as `nix/docker/buildCudaLayeredImage.nix`, outlines the process for creating a layered Docker image with CUDA support:

```nix
# https://sebastian-staffa.eu/posts/nvidia-docker-with-nix/
# https://github.com/Staff-d/nix-cuda-docker-example
{  cudatoolkit
,  buildLayeredImage
,  lib
,  name
,  tag ? null
,  fromImage ? null
,  contents ? null
,  config ? {Env = [];}
,  extraCommands ? ""
,  maxLayers ? 2
,  fakeRootCommands ? ""
,  enableFakechroot ? false
,  created ? "2024-03-08T00:00:01Z"
,  includeStorePaths ? true
}:

let

  # cut the patch version from the version string
  cutVersion = with lib; versionString:
    builtins.concatStringsSep "."
      (take 3 (builtins.splitVersion versionString )
    );

  cudaVersionString = "CUDA_VERSION=" + (cutVersion cudatoolkit.version);

  cudaEnv = [
    "${cudaVersionString}"
    "NVIDIA_VISIBLE_DEVICES=all"
    "NVIDIA_DRIVER_CAPABILITIES=all"

    "LD_LIBRARY_PATH=/usr/lib64/"
  ];

  cudaConfig = config // {Env = cudaEnv;};

in buildLayeredImage {
  inherit name tag fromImage
    contents extraCommands
    maxLayers
    fakeRootCommands enableFakechroot
    created includeStorePaths;

  config = cudaConfig;
}
```

This Nix expression employs `buildLayeredImage` (or `streamLayeredImage` for some versions) to create a Docker image that includes CUDA support, customizing the creation date as necessary.

**Creating an Entrypoint Script**

Define an entrypoint for the Docker image in `entrypoint.sh`. This script initiates your project, ensuring it executes upon container startup:

```
#!/bin/env bash

echo "my entry point"
python -m myproject.hello
```

**Crafting the Docker Container Build Script**

The `nix/build_container.nix` script orchestrates the Docker image creation, incorporating the project and its dependencies:

```nix
{
    project_dependencies ? import ./dependencies.nix {}
}:
let
  pkgs = project_dependencies.pkgs;
  lib = project_dependencies.lib;
  cudatoolkit = project_dependencies.cudatoolkit;
  project = import ./project.nix { project_dependencies = project_dependencies; };
  entrypointScriptPath = ../entrypoint.sh; # Adjust the path as necessary
  entrypointScript = pkgs.runCommand "entrypoint-script" {} ''
    mkdir -p $out/bin
    cp ${entrypointScriptPath} $out/bin/entrypoint
    chmod +x $out/bin/entrypoint
  '';
in import ./docker/buildCudaLayeredImage.nix {
  inherit cudatoolkit;
  buildLayeredImage = pkgs.dockerTools.streamLayeredImage;
  lib = pkgs.lib;
  maxLayers = 2;
  name = "project_nix";
  tag = "latest";

  contents = [
    pkgs.coreutils
    pkgs.findutils
    pkgs.gnugrep
    pkgs.gnused
    pkgs.gawk
    pkgs.bashInteractive
    pkgs.which
    pkgs.file
    pkgs.binutils
    pkgs.diffutils
    pkgs.less
    pkgs.gzip
    pkgs.btar
    pkgs.nano
    (pkgs.python311.withPackages (ps: [
      project
    ]))
    entrypointScript
  ];
  config = {
    Entrypoint = ["${entrypointScript}/bin/entrypoint"];
  };
}
```

[Changes on GitHub](https://github.com/matthid/nix-intro-examples/commit/b5f517876ab2f7d716f004c6d9a5d9cc19247ed8?diff=unified&w=1)

**Building and Running the Container**

Execute the following command within a Nix shell to build and load your Docker image:

```shell
[nix-shell]$ $(nix-build --no-out-link nix/build_container.nix) | docker load
```

This approach maintains the integrity of your `nix/project.nix`, ensuring that the containerization process is both transparent and adaptable to project changes. For those familiar with Docker, `nix/build_container.nix` offers a clear method for containerization. Those new to Docker can rely on this script as a stable foundation, requiring little to no adjustments for different project setups.

**Executing the Docker Image**

To run your newly created Docker image:

```shell
docker run project_nix
```
This command should output:

```
My entry point
Hello, World! Cuda available: False
```

To enable CUDA, ensure you have the necessary GPU support and run:

```shell
docker run --gpus all project_nix
```

This will confirm CUDA's availability within your Dockerized environment:

```
My entry point
Hello, World! Cuda available: True
```

## Customizing Dependencies in Nix

So far, we've primarily utilized official Nix packages. However, you might encounter situations where the necessary package is unavailable or exists only in an unstable channel. In such cases, Nix's overlay system allows you to replace, change, or overwrite dependencies to meet your project's needs.



### Case Study: Integrating PyTorch Lightning

PyTorch Lightning is a prime example of a package that, at times, may only be available in the NixOS unstable channel. Moreover, integrating it might require replacing its dependency on the standard PyTorch package with a custom version. Here's how you can achieve this with a Nix overlay:

**Step 1: Define the Overlay (/nix/overlay/replace-torch.nix)**

Create an overlay file that conditionally replaces PyTorch and its related packages with alternative versions, if specified:

```nix
{ do_replace ? false
, replacement_torch ? false
, replacement_torchvision ? false
, replacement_torchaudio ? false
, replacement_python ? false }:
final: prev:
let
  real_python = if do_replace then replacement_python else prev.python311;
  real_torch = if do_replace then replacement_torch else real_python.pkgs.torch-bin;
  real_torchvision = if do_replace then replacement_torchvision else real_python.pkgs.torchvision-bin;
  real_torchaudio = if do_replace then replacement_torchaudio else real_python.pkgs.torchaudio-bin;
  real_python311 = real_python.override {
    packageOverrides = final_: prev_: {
      torch = real_torch;
      torchvision = real_torchvision;
      torchaudio = real_torchaudio;
      pytorch-lightning = prev_.pytorch-lightning.override {
        torch = real_torch;
      };
      tensorboardx = prev_.tensorboardx.override {
        torch = real_torch;
      };
    };
  };
in {
  python311 = real_python311;
  my_python = real_python311;
}

```

**Step 2: Update Your Dependencies (dependencies.nix)**

In your `nix/dependencies.nix`, incorporate the overlay and specify any replacements as needed. This configuration allows you to use both stable and unstable packages, customizing dependencies according to your project requirements:

```nix
# change dependencies.nix
{ pkgs ? import <nixpkgs> {
    overlays = [
      (import ./overlay/replace-torch.nix { })
    ];
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
  }
, lib ? pkgs.lib
, my_python ? pkgs.python3
, cudatoolkit ? pkgs.cudaPackages.cudatoolkit
, unstable_pkgs ? import (fetchTarball "https://github.com/NixOS/nixpkgs/archive/nixos-unstable.tar.gz") {
    overlays = [
      (import ./overlay/replace-torch.nix {
          do_replace = true;
          replacement_torch = my_python.pkgs.torch;
          replacement_torchvision = my_python.pkgs.torchvision;
          replacement_torchaudio = my_python.pkgs.torchaudio;
          replacement_python = my_python;
      })
    ];
  }
}:
let
  python_packages = my_python.pkgs;
  unstable_python_packages = unstable_pkgs.my_python.pkgs;
in {
  pkgs = pkgs;
  lib = lib;
  my_python = my_python;
  cudatoolkit = cudatoolkit;
  dependencies = with pkgs; [
    python_packages.numpy
    python_packages.torch-bin
    unstable_python_packages.pytorch-lightning
    cudatoolkit
  ];
}
```

**Observing the Impact**

When you rebuild your container using the specified `nix-build` command, you'll notice PyTorch Lightning among the layers—demonstrating the overlay's effect. This method grants you fine control over which packages are included in your container, ensuring that your environment aligns precisely with your project's dependencies.

[Changes on GitHub](https://github.com/matthid/nix-intro-examples/commit/e8c07e286aae8729931335b5c51486e514d47a7b?diff=unified&w=1)


**Step 3: Why do we need the overlay again?**

To illustrate the importance of overlays, consider temporarily disabling the package overrides in `nix/overlay/replace-torch.nix` by commenting out the lines related to dependency replacements:

```nix
# Within /nix/overlay/replace-torch.nix, comment out:
    packageOverrides = final_: prev_: {
      #torch = real_torch;
      #torchvision = real_torchvision;
      #torchaudio = real_torchaudio;
      #pytorch-lightning = prev_.pytorch-lightning.override {
      #  torch = real_torch;
      #};
```

Next, trigger a build process (cancel after the output starts):

```shell
[nix-shell]$ $(nix-build --no-out-link nix/build_container.nix) | docker load
these 23 derivations will be built:
  /nix/store/d9zwjxg8ny4n2ybcahmc4v4ghks801b4-cuda_nvcc-12.1.105.drv
  /nix/store/6f6fhz2awqqgrr70zp359kpx0xa6ky2d-python3.11-triton-2.1.0.drv
  /nix/store/fphiqwvnwjd4pn6pa5lj7b08gb5ns8dn-cuda_profiler_api-linux-x86_64-12.2.140-archive.tar.xz.drv
  /nix/store/g0izqr84dq53zm1vlgvq1is8l4x2sq0l-cuda_profiler_api-12.2.140.drv
  /nix/store/3p4lc5ym7hwf9lhbf3gpy89vskc89jay-cuda_nvcc-linux-x86_64-12.2.140-archive.tar.xz.drv
  /nix/store/m3i09zc16d5179wihcr0frdzl4pdrdhw-cuda_nvcc-12.2.140.drv
  /nix/store/rk04gwl9al2xjrvflph8rn0z0jnpzip8-source.drv
  /nix/store/l2mv89xq94klgrhhd33ka52rgv8rx51f-nccl-2.20.3-1.drv
  /nix/store/cynqbwdlx3dq3jcwpgqqyffwbysgq4al-cuda_nvml_dev-linux-x86_64-12.2.140-archive.tar.xz.drv
  /nix/store/pi6pqqxvb3xihs30dgshszz90ydmrnm7-cuda_nvml_dev-12.2.140.drv
  /nix/store/zwdvqi744rgx5v8z23qwdl720941dcvs-magma-2.7.2.drv
  /nix/store/6whl2wy4li5ckvpx3v1k28hry9fnly61-python3.11-torch-2.2.1.drv
  /nix/store/7b37pwvsvj0zgazb1410dlfr2qqhhhwb-python3.11-torchmetrics-1.3.1.drv
  /nix/store/6kjfz8r8g736d9a8nqkkgbb9z49jljal-python3.11-torchvision-0.17.1.drv
  /nix/store/npsah4dcxjbnnrz4g4vmb8znxr2kncjr-python3.11-tensorboardx-2.6.2.drv
  /nix/store/r6qy1qpx1084zm17rmdlsq7r2x1vpglp-python3.11-pytorch-lightning-2.1.3.drv
^Cerror: interrupted by the user

Cancel with Ctrl+C
```


You'll notice the build process attempts to rebuild `pytorch-lightning` and its dependencies from scratch, including the default `torch` package from the unstable channel, despite our previous efforts to build them with custom settings. This happens because, without the overlays, Nix falls back to using the original package definitions and dependencies.

Overlays allow us to inject our customizations into the Nix package definitions, effectively enabling us to replace certain parameters, like dependencies, with our preferred versions. When we remove the overlay customizations, Nix no longer has the instructions to use our custom dependencies and reverts to the default behavior, as illustrated by the build process attempting to fetch and build the original versions of `pytorch-lightning` and its dependencies.

By utilizing overlays, such as in our `nix/overlay/replace-torch.nix`, we gain fine-grained control over package dependencies. This method allows us to dictate exactly which versions of packages like `torch`, `torchvision`, and `torchaudio` are used, ensuring compatibility and meeting specific requirements of our project.

For a deeper dive into how packages are defined and how dependencies are managed in Nix, you can explore the official Nix package repository, such as the definition for `pytorch-lightning` [here](https://github.com/NixOS/nixpkgs/blob/nixos-23.11/pkgs/development/python-modules/pytorch-lightning/default.nix#L1).

In summary, overlays are a powerful tool in Nix for customizing package behaviors, especially for replacing dependencies. They provide a flexible way to ensure that your project uses the exact versions of packages you need, without being constrained by the defaults provided in Nix channels.

[Changes on GitHub](https://github.com/matthid/nix-intro-examples/commit/e8c07e286aae8729931335b5c51486e514d47a7b?diff=unified&w=1)

### Packaging docTR with Nix: A Practical Example

Creating a Nix package for third-party libraries such as docTR can be streamlined by leveraging tools and resources efficiently. One effective strategy I often employ involves consulting with [ChatGPT for initial guidance]((https://chat.openai.com/share/d4e8f8f8-afc1-4935-aa78-a8bcad26eac7)) and insights. The aim is to create a self-contained Nix expression that encapsulates all necessary dependencies and configurations, ensuring a smooth integration into the broader project environment.

Crafting the Nix Expression for docTR
Below is a comprehensive Nix expression for packaging the docTR library, create it at `nix/packages/doctr.nix`. This setup ensures that all parameters are optional, providing flexibility and making the package self-contained:

```nix
{ pkgs ? import <nixpkgs> {}
, lib ? pkgs.lib
, my_python ? pkgs.python311
, buildPythonPackage ? my_python.pkgs.buildPythonPackage
, fetchFromGitHub ? pkgs.fetchFromGitHub }:

buildPythonPackage rec {
  pname = "doctr";
  version = "0.8.1";  # Update this to the latest release version

  src = fetchFromGitHub {
    owner = "mindee";
    repo = pname;
    rev = "v${version}";
    sha256 = "rlIGq5iHDAEWy1I0sAXVSN2/Jh2ub/xLCLCLLp7+9ik=";  # Generate this with nix-prefetch-github
  };

  nativeBuildInputs = [ my_python.pkgs.setuptools ];
  propagatedBuildInputs = [ my_python.pkgs.torch ];


  postInstall = let
    libPath = "lib/${my_python.libPrefix}/site-packages";
  in
    ''
      mkdir -p $out/nix-support
      echo "$out/${libPath}" > "$out/nix-support/propagated-build-inputs"
    '';

  doCheck = false;

  meta = with lib; {
    description = "Doctr Python package";
    homepage = https://github.com/mindee/doctr;
    license = licenses.asl20;  # Update as per project's licensing
    maintainers = [ ];  # You need to add your name to the list of Nix maintainers
  };
}
```

To validate the package, execute:

```shell
[nix-shell]$ nix-build nix/packages/doctr.nix
```

This command builds the docTR package, allowing you to verify its correctness and functionality.

Integrating docTR into Your Project
Once the docTR package meets your requirements, incorporate it into your project's dependencies by updating `nix/dependencies.nix`. This ensures docTR is recognized as part of your project's environment and can be used alongside other dependencies:

```nix
# ... previous content omitted for brevity ...
let
  python_packages = my_python.pkgs;
  unstable_python_packages = unstable_pkgs.my_python.pkgs;
  python_doctr = pkgs.callPackage ./packages/doctr.nix {
    pkgs = pkgs;
    my_python = my_python;
  };
in {
  pkgs = pkgs;
  lib = lib;
  my_python = my_python;
  cudatoolkit = cudatoolkit;
  python_doctr = python_doctr; # optional: Make it available if you need it
  dependencies = with pkgs; [
    python_packages.numpy
    python_packages.torch-bin
    unstable_python_packages.pytorch-lightning
    python_doctr
    cudatoolkit
  ];
}
```

By following these steps, you seamlessly integrate docTR into your project, enabling its use within the Nix-managed environment. This approach not only highlights the flexibility and power of Nix in handling complex dependencies but also demonstrates a practical workflow for incorporating third-party Python libraries into your development ecosystem.


[Changes on GitHub](https://github.com/matthid/nix-intro-examples/commit/ae5d9c459639b4e984a369e471e11bfe2134478c?diff=unified&w=1)

### Tailoring ffmpeg with Custom Build Flags in Nix

Achieving a tailored build of complex dependencies like ffmpeg, especially with custom flags, can often be cumbersome on traditional systems. Nix, however, simplifies this process remarkably well through the use of overlays. This approach allows you to specify custom build options without altering the package's default configuration.

Creating an ffmpeg Overlay
To customize ffmpeg, you'll start by defining an overlay. This is done in a file named `nix/overlay/ffmpeg.nix`, where you can specify your desired build flags:

```
# https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/libraries/ffmpeg/generic.nix
self: super: {
  ffmpeg = super.ffmpeg.override {
    withDebug = false;
    buildFfplay = false;
    withHeadlessDeps = true;
    withCuda = true;
    withNvdec = true;
    withFontconfig = true;
    withGPL = true;
    withAom = true;
    withAss = true;
    withBluray = true;
    withFdkAac =true;
    withFreetype = true;
    withMp3lame = true;
    withOpencoreAmrnb = true;
    withOpenjpeg = true;
    withOpus = true;
    withSrt = true;
    withTheora = true;
    withVidStab = true;
    withVorbis = true;
    withVpx = true;
    withWebp = true;
    withX264 = true;
    withX265 = true;
    withXvid = true;
    withZmq = true;
    withUnfree = true;
    withNvenc = true;
    buildPostproc = true;
    withSmallDeps = true;
  };
}
```

This overlay script overrides the default ffmpeg package to fine-tune its features and codecs based on your project's requirements.

Integrating the Overlay
Next, incorporate this overlay into your Nix environment by adding it to the list of overlays in `nix/dependencies.nix`:

```nix
{ pkgs ? import <nixpkgs> {
    overlays = [
      (import ./overlay/replace-torch.nix { })
      (import ./overlay/ffmpeg.nix)
    ];
    config = {
      allowUnfree = true;
      cudaSupport = true;
    };
  }
# Remaining content omitted for brevity
```

By adding the ffmpeg overlay to your environment, you enable the custom-configured ffmpeg build across your Nix-managed project.

Quick Testing in `nix/shell.nix`
To ensure everything is set up correctly, include ffmpeg in the `buildInputs` of your `nix/shell.nix`:

```nix
# ... previous content omitted for brevity ...
  buildInputs = [
    pkgs.python3
    myProject
    pkgs.git
    pkgs.curl
    pkgs.linuxPackages.nvidia_x11
    pkgs.ncurses5
    pkgs.ffmpeg
  ];
# ... previous content omitted for brevity ...
```

Verifying the Custom ffmpeg Build
Exit any existing Nix shell sessions and re-enter to load the latest configurations. Then, test your ffmpeg build to confirm the custom flags are active:

```
[nix-shell]$ exit
$ nix-shell nix/shell.nix # Might take a while as it compiles ffmpeg
[nix-shell]$ ffmpeg -version
```

The output should reflect your custom build settings, indicating success:

```
ffmpeg version 6.1 Copyright (c) 2000-2023 the FFmpeg developers
built with gcc 13.2.0 (GCC)
configuration: ... --enable-cuda --disable-cuda-llvm ...
```

[Changes on GitHub](https://github.com/matthid/nix-intro-examples/commit/70ff74de181b094a7ac55fcdebb45f1536bef6dc?diff=unified&w=1)

## Optimizing Docker Container Layering with Custom Strategies

The quest for efficient Docker container layering led me to develop a solution that deviates from traditional approaches: [nix-docker-layering](https://github.com/matthid/nix-docker-layering). Standard layering often results in an imbalance, where initial layers are disproportionately small, and a bulk of dependencies get pushed to the final layer. This default method layers each package individually, prioritizing those with the widest dependency reach.

The `nix-docker-layering` project introduces a novel strategy, `generators.equal`, which aims to distribute packages more evenly across layers, thus achieving a more balanced size distribution. Here’s how you can integrate this approach:

**Step 1:** Modify `nix/docker/buildCudaLayeredImage.nix` to include two new parameters provided by `nix-docker-layering`, passing them to the `buildLayeredImage` function:

```
#...
,  slurpfileGenerator
,  genArgs ? {}
# ...
in buildLayeredImage {
  inherit name tag fromImage
    contents extraCommands
    maxLayers
    fakeRootCommands enableFakechroot
    created includeStorePaths
    slurpfileGenerator genArgs;
#...
```

**Step 2:** Integrate the `nix-docker-layering` project into `nix/build_container.nix`, specifying the desired strategy and adjusting `maxLayers` for enhanced layering:

```
# ...
let
  pkgs = project_dependencies.pkgs;
  docker_layering = (import (fetchTarball {
    # URL of the tarball archive of the specific commit, branch, or tag
    url = "https://github.com/matthid/nix-docker-layering/archive/1.0.0.tar.gz";
    sha256 = "0g5y363m479b0pcyv0vkma5ji3x5w2hhw0n61g2wgqaxzraaddva";
  }) { inherit pkgs; });
# ...

in import ./docker/buildCudaLayeredImage.nix {
  inherit cudatoolkit;
  buildLayeredImage = docker_layering.streamLayeredImage;
  slurpfileGenerator = docker_layering.generators.equal;
  lib = pkgs.lib;
  maxLayers = 20;
#...
```

**Step 3:** Evaluate the new layering strategy by building and loading your Docker container:

```shell
[nix-shell]$ $(nix-build --no-out-link nix/build_container.nix) | docker load
```

Post-build, the output should reveal a more strategic distribution of layers:

```
...
Using size 825445781 (15683469850 / 19).
Adding layer 0 with size 826521078 and 271 elements.
Adding layer 1 with size 1035341240 and 12 elements.
Adding layer 2 with size 847073011 and 55 elements.
Adding layer 3 with size 1189094488 and 5 elements.
Adding layer 4 with size 1276134933 and 1 elements.
Adding layer 5 with size 933546895 and 2 elements.
Adding layer 6 with size 946925035 and 8 elements.
Adding layer 7 with size 833358245 and 44 elements.
Adding layer 8 with size 1726895617 and 43 elements.
Adding layer 9 with size 1067920473 and 69 elements.
Adding layer 10 with size 4994209074 and 4 elements.
Adding (last) layer 11 with size 6449761
...
Creating layer 12 from paths: [... '/nix/store/gpwxhvj47vrpp7szyzlvq1s4pz7q55k9-python3.11-myproject-0.1' ...]
```

This customized strategy results in a pragmatic balance: initial layers house the foundational packages least likely to change, while the application itself resides in the accessible final layer. Notably, the effective layer count may fall short of `maxLayers` due to the strategy's efficient packing approach, which aims to minimize the last layer's size and accommodate oversized packages as seen.


[Changes on GitHub](https://github.com/matthid/nix-intro-examples/commit/357881a7081e43a4a5cbfb61204f3cbdc00c07a5?diff=unified&w=1)

## Conclusion

Embarking on the journey with Nix, from the fundamentals to advanced techniques, demonstrates its profound impact on simplifying and optimizing project management and deployment. This exploration has not only highlighted Nix's capabilities in managing dependencies but also its flexibility in integrating with diverse ecosystems, from simple Python applications to complex Docker containerization strategies.

### Embracing the Power of Nix

The versatility of Nix, illustrated through real-world examples, offers a glimpse into its potential to revolutionize development workflows. By leveraging Nix, we navigated the intricacies of dependency management, package customization, and even refined Docker container layering, showcasing Nix's ability to cater to specific project needs while ensuring consistency and reproducibility.

### A Resource for the Nix Community

To support your journey with Nix, I've compiled the complete project, including all intermediate steps, as a series of commits in a GitHub repository: [nix-intro-examples](https://github.com/matthid/nix-intro-examples). This resource is designed to provide hands-on guidance and inspire further exploration into the endless possibilities Nix offers.

### Final Thoughts

The transition to Nix for dependency management and beyond represents not just a shift in tools but a paradigm change towards a clearer, more manageable approach to software development. I hope this guide serves as a beacon for those navigating the complexities of dependency management, offering a path to mastery in utilizing Nix for a seamless, efficient development experience.
