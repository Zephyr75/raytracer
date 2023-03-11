extern crate ocl;
use ocl::{ProQue, SpatialDims};
use sdl2::pixels::Color;
use sdl2::rect::Rect;
use sdl2::render::{Canvas, Texture, TextureCreator};
use sdl2::video::{Window, WindowContext};
use std::time::{SystemTime};

mod utils;
use utils::settings::{*, self};

fn main() -> Result<(), String> {
    // Initialize SDL2
    let sdl_context = sdl2::init()?;
    let video_subsystem = sdl_context.video()?;

    // Create a window
    let window = video_subsystem.window("Gradient Example", settings::RES_X as u32, settings::RES_Y as u32)
        .position_centered()
        .build()
        .map_err(|e| e.to_string())?;

    // Create a renderer
    let mut canvas = window.into_canvas().build().map_err(|e| e.to_string())?;

    // Create a texture creator
    let texture_creator: TextureCreator<_> = canvas.texture_creator();

    let mut now = SystemTime::now();


    /////////////////////////// OpenCL ///////////////////////////

    let dims = (settings::RES_X, settings::RES_Y);
    
    // Create a new OpenCL context and command queue
    let pro_que = ProQue::builder()
        .dims(dims)
        .src("
            __kernel void compute(__global int* array) {
                int row = get_global_id(0);
                int col = get_global_id(1);
                array[row * 1000 + col] = row * 1000 + col;
            }
        ")
        .build().unwrap();

    /////////////////////////// OpenCL ///////////////////////////

    // Wait for user input to exit
    let mut event_pump = sdl_context.event_pump()?;
    'running: loop {
        for event in event_pump.poll_iter() {
            match event {
                sdl2::event::Event::Quit {..} => break 'running,
                _ => {},
            }
        }



        // Create a buffer to hold the array on the GPU
        let image = pro_que.create_buffer::<i32>().unwrap();
        
        // Enqueue the compute kernel with the buffer and array dimensions
        let kernel = pro_que.kernel_builder("compute")
            .arg(&image)
            .global_work_size(SpatialDims::Two(dims.0, dims.1))
            .build().unwrap();

        unsafe { kernel.enq().unwrap(); }
        
        // Read the computed array back from the GPU
        let mut array = vec![0; dims.0 * dims.1];
        image.read(&mut array).enq().unwrap();




        // Create a texture with a gradient
        let texture = ray_tracing(&texture_creator, array)?;

        // Render the texture to the canvas
        canvas.copy(&texture, None, Some(Rect::new(0, 0, settings::RES_X as u32, settings::RES_Y as u32)))?;

        // Show the rendered image
        canvas.present();

        match now.elapsed() {
            Ok(elapsed) => {
                // it prints '2'
                println!("Fps: {}", 1000 / (elapsed.as_millis() + 1));
            }
            Err(e) => {
                // an error occurred!
                println!("Error: {e:?}");
            }
        }
        now = SystemTime::now();
    }

    Ok(())
}


fn ray_tracing(creator: &TextureCreator<WindowContext>, array: Vec<i32>) -> Result<Texture, String> {
    let mut texture = creator.create_texture_streaming(Some(sdl2::pixels::PixelFormatEnum::RGBA8888), settings::RES_X as u32, settings::RES_Y as u32)
        .map_err(|e| e.to_string())?;


    // Set the pixels of the texture to the gradient
    texture.with_lock(None, |buffer: &mut [u8], pitch: usize| {
        for y in 0..settings::RES_Y {
            for x in 0..settings::RES_X {
                let offset = y * pitch + x * 4;
                let color = array[y * settings::RES_X + x];
                buffer[offset] = (color >> 16) as u8;
                buffer[offset + 1] = (color >> 8) as u8;
                buffer[offset + 2] = color as u8;
                buffer[offset + 3] = 255;
            }
        }
    })?;

    Ok(texture)
}