function read_merafile(filename::String, datatype::Symbol;
                        printfields::Bool=false,
                        verbose::Bool=verbose_mode)

        return read_merafile(filename=filename,
                        datatype=datatype,
                        printfields=printfields,
                        verbose=verbose)
end

function read_merafile(filename::String;
                        datatype::Symbol=:hydro,
                        printfields::Bool=false,
                        verbose::Bool=verbose_mode)

        return read_merafile(filename=filename,
                        datatype=datatype,
                        printfields=printfields,
                        verbose=verbose)
end


# todo: select variables
function read_merafile(;
                        filename::String="",
                        datatype::Symbol=:hydro,
                        printfields::Bool=false,
                        verbose::Bool=verbose_mode)


    info = info_merafile(filename=filename,
                        datatype=datatype,
                        printfields=printfields,
                        verbose=false) # suppress screen print from info_merafile


    if datatype == :hydro
        dtype = HydroDataType()
        if verbose println() end
        printtime("Get hydro data: ", verbose)
    end


    #------------------
    #default variable selection for gethydro, getparticles, getclumps, getgravity, ....
    vars=[:all]
    lmax=info.levelmax
    # create variabe-list and vector-mask (nvarh_corr) for gethydrodata-function
    # print selected variables on screen
    nvarh_list, nvarh_i_list, nvarh_corr, read_cpu, used_descriptors = prepvariablelist(info, datatype, vars, lmax, verbose)
    #------------------

    #------------------
    # default ranges for gethydro, getparticles, getclumps, getgravity, ....
    range_unit=:standard
    xrange=[missing, missing]
    yrange=[missing, missing]
    zrange=[missing, missing]
    center = [0., 0., 0.]
    # convert given ranges and print overview on screen
    ranges = prepranges(info, range_unit, verbose, xrange, yrange, zrange, center)
    #------------------

    # read only data for database
    file = h5open(filename, "r")

        group = file[string(datatype)]
        data = group["data"]
        merafile_version = read(group["merafile_version"])
        column_names = read(data["names"])
        t = table([read(data[i]) for i in column_names]...,
        names=Symbol.(column_names), pkey=[:cx, :cy, :cz], presorted = false)


        # Fill HydroDataType
        dtype.info = info
        dtype.data = t
        dtype.lmin = read(group["lmin"])
        dtype.lmax = read(group["lmax"])
        dtype.boxlen = read(group["boxlen"])
        dtype.ranges = read(group["ranges"])
        dtype.selected_hydrovars = read(group["selected_hydrovars"])

        desc = read(group["used_descriptors"])
        if desc == 0
            dtype.used_descriptors = Dict()
        else
            dtype.used_descriptors = desc
        end
        dtype.smallr = read(group["smallr"])
        dtype.smallc = read(group["smallc"])
        dtype.scale = info.scale


        printtablememory(dtype, verbose)

        """
        if verbose
            ctype = read(group["compression_type"])
            cn    = read(group["compression"])

            println("Directory: ", info.path )
            println("merafile_version: ", merafile_version)
            println("Simulation code: ", info.simcode)
            println("DataType: ", datatype)
            println("Data variables: ", column_names)
            #if info.descriptor.usehydro
            #     println("Descriptor: ", dtype.used_descriptors )
            #end
            #println("Total fields: ", count_fields)
            println("Compression type: ", ctype, " with: ", cn )
            mem = usedmemory(dtype, false)
            println("Uncompressed memory size: ", round(mem[1], digits=3)," ", mem[2])
            s = filesize(filename)
            svalue, sunit = humanize(Float64(s), 3, "memory")
            println("File size: ", svalue, " ", sunit)
        end
        """
    close(file)
    return dtype
end