function get_data(  dataobject::HydroDataType,
                    vars::Array{Symbol,1},
                    units::Array{Symbol,1},
                    direction::Symbol,
                    center::Array{<:Any,1},
                    mask::MaskType)

    boxlen = dataobject.boxlen
    lmax = dataobject.lmax
    isamr = checkuniformgrid(dataobject, lmax)
    vars_dict = Dict()
    #vars = unique(vars)


    if direction == :z
        apos = :cx
        bpos = :cy
        cpos = :cz

        avel = :vx
        bvel = :vy
        cvel = :vz

    elseif direction == :y
        apos = :cz
        bpos = :cx
        cpos = :cy

        avel = :vz
        bvel = :vx
        cvel = :vy
    elseif direction == :x
        apos = :cz
        bpos = :cy
        cpos = :cx

        avel = :vz
        bvel = :vy
        cvel = :vx
    end


    column_names = propertynames(dataobject.data.columns)

    for i in vars

        # quantitties that are in the datatable
        if in(i, column_names)

            selected_units = getunit(dataobject, i, vars, units)
            if i == :cx
                if isamr
                    vars_dict[i] =  select(dataobject.data, apos) .- 2 .^getvar(dataobject, :level) .* center[1]
                else # if uniform grid
                    vars_dict[i] =  select(dataobject.data, apos) .- 2^lmax .* center[1]
                end
            elseif i == :cy
                if isamr
                    vars_dict[i] =  select(dataobject.data, bpos) .- 2 .^getvar(dataobject, :level) .* center[2]
                else # if uniform grid
                    vars_dict[i] =  select(dataobject.data, bpos) .- 2^lmax .* center[2]
                end
            elseif i == :cx
                if isamr
                    vars_dict[i] =  select(dataobject.data, cpos) .- 2 .^getvar(dataobject, :level) .* center[3]
                else # if uniform grid
                    vars_dict[i] =  select(dataobject.data, cpos) .- 2^lmax .* center[3]
                end
            else
                #if selected_units != 1.
                    #println(i)
                    vars_dict[i] = select(dataobject.data, i) .* selected_units
                #else
                    #vars_dict[i] = select(dataobject.data, i)
                #end
            end

        # quantitties that are derived from the variables in the data table
        elseif i == :cellsize
            selected_units = getunit(dataobject, :cellsize, vars, units)
            if isamr
                vars_dict[:cellsize] =  map(row-> dataobject.boxlen / 2^row.level * selected_units , dataobject.data)
            else # if uniform grid
                vars_dict[:cellsize] =  map(row-> dataobject.boxlen / 2^lmax * selected_units , dataobject.data)
            end
        elseif i == :jeanslength
            selected_units = getunit(dataobject, :jeanslength, vars, units)
            vars_dict[:jeanslength] = getvar(dataobject, :cs, unit=:cm_s)  .*
                                        sqrt(3. * pi / (32. * dataobject.info.constants.G))  ./
                                        sqrt.( getvar(dataobject, :rho, unit=:g_cm3) ) ./ dataobject.info.scale.cm  .*  selected_units
        elseif i == :jeansnumber
            selected_units = getunit(dataobject, :jeansnumber, vars, units)
            vars_dict[:jeansnumber] = getvar(dataobject, :jeanslength) ./ getvar(dataobject, :cellsize)


        elseif i == :freefall_time
            selected_units = getunit(dataobject, :freefall_time, vars, units)
            vars_dict[:freefall_time] = sqrt.( 3. * pi / (32. * dataobject.info.constants.G) ./ getvar(dataobject, :rho, unit=:g_cm3)  ) .* selected_units

        elseif i == :mass
            selected_units = getunit(dataobject, :mass, vars, units)
            vars_dict[:mass] =  getmass(dataobject) .* selected_units

        elseif i == :cs
            selected_units = getunit(dataobject, :cs, vars, units)
            vars_dict[:cs] =   sqrt.( dataobject.info.gamma .*
                                        select( dataobject.data, :p) ./
                                        select( dataobject.data, :rho) ) .* selected_units

        elseif i == :vx2
            selected_units = getunit(dataobject, :vx2, vars, units)
            vars_dict[:vx2] =  select(dataobject.data, :vx).^2  .* selected_units.^2
        elseif i == :vy2
            selected_units = getunit(dataobject, :vy2, vars, units)
            vars_dict[:vy2] =  select(dataobject.data, :vy).^2  .* selected_units.^2
        elseif i == :vz2
            selected_units = getunit(dataobject, :vz2, vars, units)
            vars_dict[:vz2] =  select(dataobject.data, :vz).^2  .* selected_units.^2


        elseif i == :v
            selected_units = getunit(dataobject, :v, vars, units)
            vars_dict[:v] =  sqrt.(select(dataobject.data, :vx).^2 .+
                                   select(dataobject.data, :vy).^2 .+
                                   select(dataobject.data, :vz).^2 ) .* selected_units
        elseif i == :v2
           selected_units = getunit(dataobject, :v2, vars, units)
           vars_dict[:v2] =      (select(dataobject.data, :vx).^2 .+
                                  select(dataobject.data, :vy).^2 .+
                                  select(dataobject.data, :vz).^2 ) .* selected_units .^2

        elseif i == :vϕ_cylinder

            radius = getvar(dataobject, :r_cylinder, center=center)
            x = getvar(dataobject, :x, center=center)
            y = getvar(dataobject, :y, center=center)
            vx = getvar(dataobject, :vx)
            vy = getvar(dataobject, :vy)

            # selected_units = getunit(dataobject, :vϕ, vars, units)
            # vϕ = (x .* vy .- y .* vx) ./ radius .* selected_units
            # vϕ[isnan.(vϕ)] .= 0 # overwrite NaN due to radius = 0
            # vars_dict[:vϕ] = vϕ


            # vϕ = omega x radius
            selected_units = getunit(dataobject, :vϕ_cylinder, vars, units)
            a = (-1 .* y) .^2 + x .^2
            b = ( x .* vy .- y .* vx) .^2
            vϕ_cylinder =  sqrt.( a .* b  ) ./ radius .^2 .* selected_units
            #(y .* (y .* vx .- x .* vy) ).^2 .- ( x .* (y .* vx .- x .* vy) ) .^2


            #(x .* vy .- y .* vx) ./ radius .* selected_units
            vϕ_cylinder[isnan.(vϕ_cylinder)] .= 0 # overwrite NaN due to radius = 0

            vars_dict[:vϕ_cylinder] = vϕ_cylinder


        elseif i == :vϕ_cylinder2
            #radius = getvar(dataobject, :r_cylinder, center=center)
            #x = getvar(dataobject, :x, center=center)
            #y = getvar(dataobject, :y, center=center)
            #vx = getvar(dataobject, :vx)
            #vy = getvar(dataobject, :vy)


            selected_units = getunit(dataobject, :vϕ_cylinder2, vars, units)
            #vϕ2 = ((x .* vy .- y .* vx) ./ radius .* selected_units ).^2
            #vϕ2[isnan.(vϕ2)] .= 0 # overwrite NaN due to radius = 0
            #vars_dict[:vϕ2] = vϕ2
            #vϕ_cylinder2 = ( sqrt.( (y .^2 .* (y .* vx .- x .* vy) .^2 ) .- ( x .^2 .* (y .* vx .- x .* vy) .^2 )  ) ./ radius .^2 .* selected_units ) .^2
            #selected_units = getunit(dataobject, :vϕ_cylinder2, vars, units)

            #vϕ_cylinder2 = ((x .* vy .- y .* vx) ./ radius .* selected_units ).^2
            #vϕ_cylinder2[isnan.(vϕ_cylinder2)] .= 0 # overwrite NaN due to radius = 0
            vars_dict[:vϕ_cylinder2] = (getvar(dataobject, :vϕ_cylinder, center=center) .* selected_units).^2



        elseif i == :vz2

            vz = getvar(dataobject, :vz)
            selected_units = getunit(dataobject, :vz2, vars, units)
            vars_dict[:vz2] =  (vz .* selected_units ).^2

        elseif i == :vr_cylinder

            radius = getvar(dataobject, :r_cylinder, center=center )
            x = getvar(dataobject, :x, center=center)
            y = getvar(dataobject, :y, center=center)
            vx = getvar(dataobject, :vx)
            vy = getvar(dataobject, :vy)


            selected_units = getunit(dataobject, :vr_cylinder, vars, units)
            vr = (x .* vx .+ y .* vy) ./ radius .* selected_units
            vr[isnan.(vr)] .= 0 # overwrite NaN due to radius = 0
            vars_dict[:vr_cylinder] =  vr

        elseif i == :vr_cylinder2

            selected_units = getunit(dataobject, :vr_cylinder2, vars, units)
            vars_dict[:vr_cylinder2] = (getvar(dataobject, :vr_cylinder, center=center) .* selected_units).^2

        elseif i == :x
            selected_units = getunit(dataobject, :x, vars, units)
            if isamr
                vars_dict[:x] =  (getvar(dataobject, apos) .* boxlen ./ 2 .^getvar(dataobject, :level) .-  boxlen * center[1] )  .* selected_units
            else # if uniform grid
                vars_dict[:x] =  (getvar(dataobject, apos) .* boxlen ./ 2^lmax .-  boxlen * center[1] )  .* selected_units
            end
        elseif i == :y
            selected_units = getunit(dataobject, :y, vars, units)
            if isamr
                vars_dict[:y] =  (getvar(dataobject, bpos) .* boxlen ./ 2 .^getvar(dataobject, :level) .- boxlen * center[2] )  .* selected_units
            else # if uniform grid
                vars_dict[:y] =  (getvar(dataobject, bpos) .* boxlen ./ 2^lmax .- boxlen * center[2] )  .* selected_units
            end
        elseif i == :z
            selected_units = getunit(dataobject, :z, vars, units)
            if isamr
                vars_dict[:z] =  (getvar(dataobject, cpos) .* boxlen ./ 2 .^getvar(dataobject, :level) .- boxlen * center[3] )  .* selected_units
            else # if uniform grid
                vars_dict[:z] =  (getvar(dataobject, cpos) .* boxlen ./ 2^lmax .- boxlen * center[3] )  .* selected_units
            end


        elseif i == :mach #no unit needed
            vars_dict[:mach] = getvar(dataobject, :v) ./ getvar(dataobject, :cs)

        elseif i == :ekin
            selected_units = getunit(dataobject, :ekin, vars, units)
            vars_dict[:ekin] =   0.5 .* getmass(dataobject)  .* getvar(dataobject, :v).^2 .* selected_units

        elseif i == :r_cylinder
            selected_units = getunit(dataobject, :r_cylinder, vars, units)
            if isamr
                vars_dict[:r_cylinder] = select( dataobject.data, (apos, bpos, :level)=>p->
                                                selected_units * sqrt( (p[apos] * boxlen / 2^p.level - boxlen * center[1] )^2 +
                                                                   (p[bpos] * boxlen / 2^p.level - boxlen * center[2] )^2 ) )
            else # if uniform grid
                vars_dict[:r_cylinder] = select( dataobject.data, (apos, bpos)=>p->
                                                selected_units * sqrt( (p[apos] * boxlen / 2^lmax - boxlen * center[1] )^2 +
                                                                   (p[bpos] * boxlen / 2^lmax - boxlen * center[2] )^2 ) )
            end
        elseif i == :r_sphere
            selected_units = getunit(dataobject, :r_sphere, vars, units)
            if isamr
                vars_dict[:r_sphere] = select( dataobject.data, (apos, bpos, cpos, :level)=>p->
                                        selected_units * sqrt( (p[apos] * boxlen / 2^p.level -  boxlen * center[1]  )^2 +
                                                               (p[bpos] * boxlen / 2^p.level -  boxlen * center[2] )^2  +
                                                               (p[cpos] * boxlen / 2^p.level -  boxlen * center[3] )^2 ) )
            else # if uniform grid
                vars_dict[:r_sphere] = select( dataobject.data, (apos, bpos, cpos)=>p->
                                        selected_units * sqrt( (p[apos] * boxlen / 2^lmax -  boxlen * center[1]  )^2 +
                                                               (p[bpos] * boxlen / 2^lmax -  boxlen * center[2] )^2  +
                                                               (p[cpos] * boxlen / 2^lmax -  boxlen * center[3] )^2 ) )
            end

        end

    end




    if length(mask) > 1
        for i in keys(vars_dict)
            vars_dict[i]=vars_dict[i][mask]
        end
    end


    if length(vars)==1
            return vars_dict[vars[1]]
    else
            return vars_dict
    end

end


function getmass(dataobject::HydroDataType;)

    lmax = dataobject.lmax
    boxlen = dataobject.boxlen
    isamr = checkuniformgrid(dataobject, lmax)

    #return select(dataobject.data, :rho) .* (dataobject.boxlen ./ 2. ^(select(dataobject.data, :level))).^3
    if isamr
        return select( dataobject.data, (:rho, :level)=>p->p.rho * (boxlen / 2^p.level)^3 )
    else # if uniform grid
        return select( dataobject.data, (:rho)=>p->p.rho * (boxlen / 2^lmax)^3 )
    end
end