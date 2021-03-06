# Multiculturalism at the Observatory SBO Imaging Workshop

This folder contains some sample SBO observation FITS files that you can use to put together a pretty picture of the Ring Nebula! The script [ImagingWorkshop.jl](ImagingWorkshop.jl) will do everything automatically, and you can run it right away as long as you have Julia installed, but it's set up for the specific naming convention of these sample FITS files. The [SBOReduction.jl](SBOReduction.jl) script should play nicely with the automatically generated SBO imaging files, so use that one if you're taking new data! It's currently saved on the SBO desktops in the Fall2021/1040 folder. The notebook [ImagingWorkshop.ipynb](ImagingWorkshop.ipynb) is a more guided approach that illustrates what the script is doing behind the scenes and walks you through step by step on how to reduce data from a telescope and produce a pretty, science ready image. It's also better commented than the script is.

**Limitations**: The script can handle more than one dark, bias, flat, etc. but currently assumes there is only one exposure in each color channel in the folder -- so multiple observations in the same folder or image stacking is currently not supported. It will search for RGB channels by default, and if one or more is missing but there is another option it will ask you if you'd like to replace it. Occasionally the script will ask for user input -- you must follow the directions and requested number format exactly or else it will error out as I was too lazy to implement user-friendly fail safes sorry. 

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
