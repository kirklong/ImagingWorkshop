#!/usr/bin/env julia
using Plots, FITSIO, DataFrames, Statistics, StatsBase, Images, Dates
import FileIO

function main(shift=false)
    gr(format=:png); default(fontfamily="times",widen=false,tickdirection=:out,tickfontsize=18,guidefontsize=20) #plot defaults
    #READ IN DATA
    dir = "G:\\My Drive\\Classes\\Fall2021\\Default\\$(today())"
    print("Hello! By default I will look in the folder $dir for FITS files -- please confirm (y/n): ")
    accept = readline() == "y" ? true : false
    if accept == false
        print("Enter full directory path (without quotation marks) where I should look for observation files: ")
        dir = readline()
    end
    println("Reading in FITS files located at $dir")
    cd(dir)
    files = filter(x->occursin(".fit",x),readdir()) #readdir() creates a list of files in the current directory, which we then `filter` to find only those that end with ".fits" since those are our images!
    test = FITS(files[1]) #let's see what one is like
    filters = Array{String,1}(undef,length(files)); exposures = Array{Float64,1}(undef,length(files))#initialize an empty "DataFrame" (basically a fancy table) with keys "file", "filter", and "exposure" with types String, String, and Float64
    for i=1:length(files) #iterate through every one of our files
        f = files[i]
        header = read_header(FITS(f)[1]) #read the header of the current file
        filters[i] = header["FILTER"]
        s = split(f,"-") #SBO file names go like TARGET-EXP-FILTER-NUM.fit
        if length(s) == 2 #bias ones go like Bias-NUM.fit
            exposures[i] = 0. #bias frames should have zero exposure time
        else
            exposures[i] = tryparse(Float64,s[2][1:end-4])
        end
    end
    images = []; imageType = typeof(test[1]) #initialize empty images list, get the type of an image from our "test" sample above -- ImageHDU
    for f in files #loop through all the fits files
        fits = FITS(f) #get the data from FITSIO
        for hdu in fits #iterate through the different "header data units" in each fits
            if typeof(hdu) == imageType #is it an image?
                push!(images,read(hdu)) #plop it in our images list if the type matches!
            end
        end
    end
    images = [Int32.(images[i]) for i=1:length(images)]
    #IDENTIFY INDICES OF TYPES OF IMAGES
    darkInds = []; biasInds = []; flatInds = []; imgInds = []
    i=1
    for i=1:length(files)
        f = files[i]
        imgType = split(f,"-")[1]
        if imgType == "Bias"
            push!(biasInds,i)
        elseif imgType == "FlatField"
            push!(flatInds,i)
        elseif imgType == "Dark"
            push!(darkInds,i)
        else
            push!(imgInds,i)
        end
    end
    #REDUCE DATA
    println("Files read in -- now reducing the data!")
    darkImgs = [images[i] for i in darkInds]#according to our table from before these ones were the "dark" frames
    darkMaster = zeros(size(darkImgs[1])) #let's initialize an array for our "master" dark frame that's the same size as the existing dark images
    for i=1:size(darkMaster)[1] #iterate through every x possibility
        for j=1:size(darkMaster)[2] #iterate through every y possibility
            darkMaster[i,j] = median([darkImgs[I][i,j] for I=1:length(darkImgs)]) #the "master" frame at position x,y (i,j) should be the median of the three initial dark frames at that same position
        end
    end

    #now let's do something similar for our bias images
    biasImgs = [images[i] for i in biasInds] #according to our table the first 3 were the bias images
    biasMaster = zeros(size(biasImgs[1])) #again we initialize an empty 2D array for our bias "master" that's the same size as one of the existing images
    for i=1:size(biasMaster)[1] #iterate through x
        for j=1:size(biasMaster)[2] #and y
            biasMaster[i,j] = median([biasImgs[I][i,j] for I=1:length(biasImgs)]) #again we set the master value at each x,y position to be the median of the three provided frames
        end
    end

    #and we'll do something slightly more complicated for the flat images
    flatImgs = [images[i] .- biasMaster for i in flatInds] #images 4-6 are the "flat" images, and we are subtracting the bias from them here
    flatImgs = flatImgs./(maximum(mode.(flatImgs))) #now we divide all of them by the maximum mode between them to rescale
    normFlatMaster = zeros(size(flatImgs[1])) #we again preallocate a matching 2D array that will be our "normalized flat master" image
    for i=1:size(normFlatMaster)[1] #loop x
        for j=1:size(normFlatMaster)[2] #and y
            normFlatMaster[i,j] = median([flatImgs[I][i,j] for I=1:length(flatImgs)]) #again we now set the x,y position of our master to be the median of the three existing images
        end
    end
    normFlatMaster = normFlatMaster./mode(normFlatMaster)

    #now let's reduce!
    rawImgs = [images[i] for i in imgInds]
    reduced = [(rawImgs[i] .- darkMaster)./normFlatMaster for i=1:length(rawImgs)]
    println("Data reduced -- now working on making a picture!")
    #match indices to reduced arrays
    i=1; rInd = nothing; gInd = nothing; bInd = nothing; cInd = nothing; otherFilters=[]
    for filter in filters
        if i ∉ biasInds && i ∉ flatInds && i ∉ darkInds
            if filter == "Clear"
                cInd = i
            elseif filter == "Red" || filter == "r`"
                rInd = i
            elseif filter == "Green" || filter == "g`"
                gInd = i
            elseif filter == "Blue" || filter == "b`"
                bInd = i
            else
                println("Detected non RGB filter: $filter with exposure time $(exposures[i])s -- adding it to list of potential substitutions")
                push!(otherFilters,(filter,i))
            end
        end
        i+=1
    end
    if rInd != nothing
        for i=1:length(imgInds)
            if imgInds[i] == rInd
                rInd = i
            end
        end
    end
    if gInd != nothing
        for i=1:length(imgInds)
            if imgInds[i] == gInd
                gInd = i
            end
        end
    end
    if bInd != nothing
        for i=1:length(imgInds)
            if imgInds[i] == bInd
                bInd = i
            end
        end
    end
    if cInd != nothing
        for i=1:length(imgInds)
            if imgInds[i] == cInd
                cInd = i
            end
        end
    end
    #now we can make the picture
    r,g,b = nothing, nothing, nothing
    if rInd != nothing && gInd != nothing && bInd != nothing
        r,g,b = reduced[rInd],reduced[gInd],reduced[bInd]
    else
        println("I don't have complete r,g,b set.\n")
        if length(otherFilters)>0
            println("I have these other filters available as substitutions:")
            count = 1
            for tup in otherFilters
                f,ind = tup
                println("$count: $f")
                count+=1
            end
            println("")
            if rInd == nothing
                print("Missing red filter -- select the number corresponding to filter in list above you would like to use to replace it (must be integer): ")
                tupInd = tryparse(Int64,readline())
                f,rInd = otherFilters[tupInd]
                for j=1:length(imgInds)
                    if imgInds[j] == rInd
                        rInd = j
                    end
                end
            end
            if gInd == nothing
                print("Missing green filter -- select the number corresponding to filter in list above you would like to use to replace it (must be integer): ")
                tupInd = tryparse(Int64,readline())
                f,gInd = otherFilters[tupInd]
                for j=1:length(imgInds)
                    if imgInds[j] == gInd
                        gInd = j
                    end
                end
            end
            if bInd == nothing
                print("Missing blue filter -- select the number corresponding to filter in list above you would like to use to replace it (must be integer): ")
                tupInd = tryparse(Int64,readline())
                f,bInd = otherFilters[tupInd]
                for j=1:length(imgInds)
                    if imgInds[j] == bInd
                        bInd = j
                    end
                end
            end
            r,g,b = reduced[rInd],reduced[gInd],reduced[bInd]
        end
    end
    C = reduced[cInd]
    if r != nothing
        println("We have colors! Making a color image.")
        newImg = zeros(3,size(r)[2],size(r)[1]) #rgb,y,x
        for i=1:size(newImg)[1]
            for j=1:size(newImg)[3]
                for k=1:size(newImg)[2] #k,j swap rotates below
                    if i==1
                        newImg[i,k,j]= r[j,k] #red channel
                    elseif i==2
                        newImg[i,k,j]= g[j,k]#green channel
                    else
                        newImg[i,k,j]= b[j,k]#blue channel
                    end
                end
            end
        end
        img = newImg./(maximum(newImg)/30) #this controls the "exposure" -- /100 for overexposure to see galaxy
        rgbCube = reverse(img,dims=2) #reverse it? yes, this works and matches orientation of "real" pictures (fixes y direction)
        shape = size(rgbCube) #get the shape
        rgbCube = vec(rgbCube) #unravel it
        rgbCube[rgbCube.<0.0] .= 0.0; rgbCube[rgbCube.>1.0] .= 1.0 #make sure all the values are between 0 and 1
        rgbCube = reshape(rgbCube,shape)
        save("RGB.png",colorview(RGB,rgbCube)) #save the picture
        if shift == true
            img = FileIO.load("RGB.png")
            println("Look at the raw image and identify a region (in pixel coordinates) that has an isolated, bright star")
            endY=size(r)[2]
            YTicks=([endY-100*i for i=0:convert(Int64,floor(size(r)[2]/100))],["$(100*i)" for i=0:convert(Int64,floor(size(r)[2]/100))])
            XTicks=([100*i for i=0:convert(Int64,floor(size(r)[1]/100))],["$(100*i)" for i=0:convert(Int64,floor(size(r)[1]/100))])
            p=plot(img,aspect_ratio=:equal,grid=true,minorgrid=true,minorticks=5,yminorticks=5,xlabel="x (detector)",ylabel="y (detector)",
                size=size(r),yticks=YTicks,xticks=XTicks,bottom_margin=10*Plots.Measures.mm,left_margin=10*Plots.Measures.mm,xlims=(0,size(r)[1]),ylims=(0,size(r)[2]))
            p=vline!(xticks(p)[1][1],lc=:white,linealpha=0.5,label="")
            p=hline!(yticks(p)[1][1],lc=:white,linealpha=0.5,label="")
            display(p)
            print("Enter min x value (integer): ")
            minX = tryparse(Int64,readline())
            print("Enter max x value (integer): ")
            maxX = tryparse(Int64,readline())
            print("Enter min y value (integer): ")
            minY = tryparse(Int64,readline())
            print("Enter max y value (integer): ")
            maxY = tryparse(Int64,readline())
            println("Making image using matched centroids in specified region")
            function centroid(img,c,Δx,Δy) #get the centroid of a slice of an image
                xRange = [c[1]-Δx,c[1]+Δx]; yRange = [c[2]-Δy,c[2]+Δy]
                x = range(c[1]-Δx,stop=c[1]+Δx,length=2*Δx+1); y = range(c[2]-Δy,stop=c[2]+Δy,length=2*Δy+1)
                sub=img[xRange[1]:xRange[2],yRange[1]:yRange[2]] #image subsection bounded by xRange, yRange
                xIntensity = [sum(sub[i,:]) for i=1:size(sub)[1]]; yIntensity = [sum(sub[:,i]) for i=1:size(sub)[2]] #get the intensity in just the x and y directions
                xCen = sum(xIntensity.*x)/sum(xIntensity); yCen = sum(yIntensity.*y)/sum(yIntensity) #calculate the centroids using weighted average formula
                return round(xCen), round(yCen) #return them rounded to nearest integer (pixel)
            end
            c = convert.(Int64,[floor((minX+maxX)/2),floor((minY+maxY)/2)])
            Δx = convert(Int64,(maxX-minX)/2); Δy = convert(Int64,(maxY-minY)/2)
            rCenX,rCenY = centroid(r,c,Δx,Δy)
            gCenX,gCenY = centroid(g,c,Δx,Δy)
            bCenX,bCenY = centroid(b,c,Δx,Δy)
            Δxg = convert(Int64,rCenX-gCenX); Δyg = convert(Int64,rCenY-gCenY)
            Δxb = convert(Int64,rCenX-bCenX); Δyb = convert(Int64,rCenY-bCenY)
            ΔxSigned = [Δxg,Δxb]; ΔySigned = [Δyg,Δyb]
            Δx,indX = findmax(abs.(ΔxSigned)); Δy,indY = findmax(abs.(ΔySigned))
            rgLeft = 0; rbLeft = 0; rgDown = 0; rbDown = 0
            Δx = convert(Int64,Δx); Δy = convert(Int64,Δy)

            newImg = zeros(3,size(r)[2]-Δy,size(r)[1]-Δx)
            Δx = ΔxSigned[indX]; Δy = ΔySigned[indY]
            rLAdd = 0; rDAdd = 0; bLAdd = 1; bDAdd = 1; gLAdd = 1; gDAdd = 1 #they should start as opposites
            if Δx > 0
                rLAdd = 1
                if Δx == Δxg
                    gLAdd = 0 #this is the one we're matching "to", it should be opposite
                elseif Δx == Δxb
                    bLAdd = 0
                end
            end

            if Δy > 0
                rDAdd = 1
                if Δy == Δyg
                    gDAdd = 0
                elseif Δy == Δyb
                    bDAdd = 0
                end
            end
            Δx = abs(Δx); Δy = abs(Δy); Δxg = abs(Δxg); Δxb = abs(Δxb); Δyg = abs(Δyg); Δyb = abs(Δyb)
            for i=1:size(newImg)[1]
                for j=1:size(newImg)[3]
                    for k=1:size(newImg)[2] #k,j swap rotates below, no longer dividing by clear image, instead normalizing different way
                        if i==1
                            newImg[i,k,j]= r[j+Δx*rLAdd,k+Δy*rDAdd] #red
                        elseif i==2
                            newImg[i,k,j]= g[j+Δxg*gLAdd,k+Δyg*gDAdd]#green
                        else
                            newImg[i,k,j]= b[j+Δxb*bLAdd,k+Δyb*bDAdd]#blue
                        end
                    end
                end
            end
            satSample = [1,10,25,50,100,200]
            for sat in satSample
                img = newImg./(maximum(newImg)/sat)
                rgbCube = reverse(img,dims=2) #reverse it? yes, this works and matches orientation of "real" pictures (fixes y direction)
                shape = size(rgbCube)
                rgbCube = vec(rgbCube)
                rgbCube[rgbCube.<0.0] .= 0.0; rgbCube[rgbCube.>1.0] .= 1.0
                rgbCube = reshape(rgbCube,shape)
                save("RGB_sat_$sat.png",colorview(RGB,rgbCube)) #save the picture
            end
            p=plot(layout=grid(2,3),size=(1920,1080),showaxis=false)
            for i=1:length(satSample)
                img = FileIO.load("RGB_sat_$(satSample[i]).png")
                plot!(p[i],img,title="Saturation = $(satSample[i])",showaxis=false,xticks=false,yticks=false)
            end
            display(p)
            print("Select saturation level using samples below (must be integer): ")
            sat = tryparse(Int64,readline())
            foreach(rm,["RGB_sat_$s.png" for s in satSample]) #clean up files
            println("Making final image -- saving as RBG_FINAL_sat_$sat.png")
            closeall()
            img = newImg./(maximum(newImg)/sat)
            rgbCube = reverse(img,dims=2) #reverse it? yes, this works and matches orientation of "real" pictures (fixes y direction)
            shape = size(rgbCube)
            rgbCube = vec(rgbCube)
            rgbCube[rgbCube.<0.0] .= 0.0; rgbCube[rgbCube.>1.0] .= 1.0
            rgbCube = reshape(rgbCube,shape)
            save("RGB_Final_sat_$sat.png",colorview(RGB,rgbCube)) #save the picture
        end
    else
        println("Could not detect r,g,b channels -- making a B&W image.")
        p = heatmap(C',c=:bone,aspect_ratio=:equal,clim=(0,1000),xlabel="x (detector)",ylabel="y (detector)",
        title = "Clear reduced image, saturated at 1000 counts",grid=false,
        xlims=(0,size(C)[1]),ylims=(0,size(C)[2]))
        png(p,"Clear.png")
    end
end

main(true)
