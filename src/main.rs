extern crate ocl;
use ocl::{ProQue, SpatialDims, Buffer, MemFlags};
extern crate ocl_extras;
use rand::{Rng, thread_rng};
use sdl2::rect::Rect;
use sdl2::render::{Texture, TextureCreator};
use sdl2::video::{WindowContext};
use std::thread::Builder;
use std::time::{SystemTime};
use rayon::prelude::*;
extern crate glam;

// impoort sdl color
use sdl2::pixels::Color;

mod utils;
use utils::settings::{*, self};

mod components;
use components::camera::Camera;

fn main() -> Result<(), String> {
    // Initialize SDL2
    let sdl_context = sdl2::init()?;
    let video_subsystem = sdl_context.video()?;

    // Create a window
    let window = video_subsystem.window("Raytracer", settings::RES_X as u32, settings::RES_Y as u32)
        .position_centered()
        .build()
        .map_err(|e| e.to_string())?;

    // Create a renderer/pop-os/cosmic-comp
    let mut canvas = window.into_canvas().build().map_err(|e| e.to_string())?;

    // Create a texture creator
    let texture_creator: TextureCreator<_> = canvas.texture_creator();

    let mut now = SystemTime::now();


    /////////////////////////// OpenCL ///////////////////////////

    let dims = (settings::RES_X, settings::RES_Y);

    // Load the OpenCL kernel code from concatenating all .cl files in the src/kernel directory
    let src = std::fs::read_to_string("src/kernel/compute.cl").unwrap();
    // src.push_str(&std::fs::read_to_string("src/kernel/compute.cl").unwrap());

    
    // Create a new OpenCL context and command queue
    let pro_que = ProQue::builder()
        .dims(dims)
        .src(src)
        .build().unwrap();

    // Create a buffer to hold the array on the GPU
    let image = pro_que.create_buffer::<i32>()?;

    // Create a buffer to hold 50 random floats to pass to the kernel
    // let randoms = ocl_extras::scrambled_vec((0.0, 2.0), pro_que.dims().to_len());

    const SIZE: usize = 50;

    //create a vector of random numbers
    let mut rng = thread_rng();
    let random_values: Vec<f32> = (0..50).map(|_| rng.gen_range(0.0..1.0)).collect();
    let randoms_buffer = pro_que.create_buffer::<f32>()?;
    randoms_buffer.write(&random_values).enq().unwrap();
    
    // Wait for user input to exit
    let mut event_pump = sdl_context.event_pump()?;
    'running: loop {
        for event in event_pump.poll_iter() {
            match event {
                sdl2::event::Event::Quit {..} => break 'running,
                _ => {},
            }
        }
        
        
        
        // Enqueue the compute kernel with the buffer and array dimensions
        let kernel = pro_que.kernel_builder("compute")
            .arg(&image)
            .arg(settings::RES_X as i32)
            .arg(settings::RES_Y as i32)
            .arg(settings::BOUNCES as i32)
            .arg(&randoms_buffer)
            .global_work_size(SpatialDims::Two(dims.0, dims.1))
            .build()?;

        kernel.set_arg(4, Some(&randoms_buffer))?;

        unsafe { kernel.enq()?; }
        
        // Read the computed array back from the GPU
        let mut array = vec![0; dims.0 * dims.1];
        image.read(&mut array).enq()?;

        // Create a texture with a gradient
        let texture = ray_tracing(&texture_creator, &array)?;

        // Render the texture to the canvas
        canvas.copy(&texture, None, Some(Rect::new(0, 0, settings::RES_X as u32, settings::RES_Y as u32)))?;

        // Show the rendered image
        canvas.present();

        match now.elapsed() {
            Ok(elapsed) => {
                // it prints '2'
                println!("fps: {}", 1000 / (elapsed.as_millis() + 1));
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


fn ray_tracing<'a>(creator: &'a TextureCreator<WindowContext>, array: &'a Vec<i32>) -> Result<Texture<'a>, String> {
    let mut texture = creator.create_texture_streaming(Some(sdl2::pixels::PixelFormatEnum::RGBA8888), settings::RES_X as u32, settings::RES_Y as u32)
        .map_err(|e| e.to_string())?;

    // Set the pixels of the texture to the gradient
    texture.with_lock(None, |buffer: &mut [u8], _pitch: usize| {
        buffer.par_chunks_mut(4 * settings::RES_X)
        .enumerate()
        .for_each(|(y, row)| {
            for x in 0..settings::RES_X {
                let offset = x * 4;
                let color = array[y * settings::RES_X + x];
                row[offset] = (color >> 24) as u8;
                row[offset + 1] = (color >> 16) as u8;
                row[offset + 2] = (color >> 8) as u8;
                row[offset + 3] = color as u8;
            }
        });
    })?;

    Ok(texture)
}