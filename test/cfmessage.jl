using Test

using GRIB


@testset "from_grib_date_time" begin
    result = CfGRIB.from_grib_date_time(20160706, 1944)

    @test result == 1467834240
end


@testset "test_build_valid_time" begin
    forecast_reference_time = [0]
    forecast_period = [0]

    vt_dims, vt_data = CfGRIB.build_valid_time(
        forecast_reference_time,
        forecast_period
    )

    @test vt_dims == ()
    @test size(vt_data) == ()


    forecast_reference_time = [0, 31536000]
    forecast_period = 0

    vt_dims, vt_data = CfGRIB.build_valid_time(
        forecast_reference_time,
        forecast_period
    )

    @test vt_dims == ("time", )
    @test size(vt_data) == (2, )


    forecast_reference_time = 0
    forecast_period = [0, 12, 24, 36]

    vt_dims, vt_data = CfGRIB.build_valid_time(
        forecast_reference_time,
        forecast_period
    )

    @test vt_dims == ("step", )
    @test size(vt_data) == (4,)
    # @test np.allclose((data - data[..., :1]) / 3600, forecast_period)


    forecast_reference_time = [0, 31536000]
    forecast_period = [0, 12, 24, 36]

    vt_dims, vt_data = CfGRIB.build_valid_time(
        forecast_reference_time,
        forecast_period
    )

    @test vt_dims == ("time", "step")
    #  TODO: Julia is column major, numpy is row major, not too sure what
    #  the correct approach would be here...
    @test size(vt_data) == (4, 2)
    # @test np.allclose((data - data[..., :1]) / 3600, forecast_period)
end
