# Multiculturalism at the Observatory SBO Imaging Workshop

This folder contains some sample SBO observation FITS files that you can use to put together a pretty picture of the Ring Nebula! The script [ImagingWorkshop.jl](ImagingWorkshop.jl) will do everything automatically, and you can run it right away as long as you have Julia installed. it should also work for any set of FITS files so long as they follow the same naming conventions (i.e. the bias frames have BIAS in them, the HDUs indicate the r,g,b filters, etc.). The notebook [ImagingWorkshop.ipynb](ImagingWorkshop.ipynb) is a more guided approach that illustrates what the script is doing behind the scenes and walks you through step by step on how to reduce data from a telescope and produce a pretty, science ready image. It's also better commented than the script is.

## Prerequisites:

**Julia** (version > 1.6) &mdash; you can find installation instructions for your operating system [here](https://julialang.org/downloads/).

You will then need to install the following Julia packages: IJulia, DataFrames, Plots, FITSIO, StatsBase, Statistics, Images, and FileIO. You can do this by entering the Julia REPL (i.e. launch Julia from the start menu, type julia in the command line window, etc. until you see the `julia>` prompt) and then typing the right bracket (`]`) key to get to the package manager. From there you should see something that looks like:

```julia
(@v1.6) pkg>
```

Then you can just type `add IJulia, DataFrames, Plots, FITSIO, StatsBase, Statistics, Images, FileIO` and they should all install *automagically*.

You should then be able to launch the Jupyter notebook, assuming you already have that installed. If you don't, getting that is easy also! There are many ways to do this, but one easy/fast way is to just install [Anaconda](https://www.anaconda.com/download/), which will include all of the Jupyter tools. Then launch Anaconda Navigator and click the Jupyter notebook icon and you should be in business.

Enjoy!

![M57RGB](M57RGB.png)
