extern crate glam;


pub struct Camera {
    // The aspect ratio of the camera
    pub aspect_ratio: f32,
    // The height of the viewport
    pub viewport_height: f32,
    // The width of the viewport
    pub viewport_width: f32,
    // The focal length of the camera
    pub focal_length: f32,
    // The origin of the camera
    pub origin: glam::Vec3,
    // The vertical vector of the camera
    pub vertical: glam::Vec3,
    // The horizontal vector of the camera
    pub horizontal: glam::Vec3,
    // The lower left corner of the viewport
    pub lower_left_corner: glam::Vec3,
}

impl Camera {
    pub fn new() -> Camera {
        let aspect_ratio = 16.0 / 9.0;
        let viewport_height = 2.0;
        let viewport_width = aspect_ratio * viewport_height;
        let focal_length = 1.0;

        let origin = glam::Vec3::new(0.0, 0.0, 0.0);
        let vertical = glam::Vec3::new(0.0, 1.0, 0.0);
        let horizontal = glam::Vec3::new(1.0, 0.0, 0.0);
        let lower_left_corner = origin - horizontal / 2.0 - vertical / 2.0 - glam::Vec3::new(0.0, 0.0, focal_length);

        Camera {
            aspect_ratio,
            viewport_height,
            viewport_width,
            focal_length,
            origin,
            vertical,
            horizontal,
            lower_left_corner,
        }
    }

    pub fn get_ray(&self, u: f32, v: f32) -> glam::Vec3 {
        self.lower_left_corner + u * self.horizontal + v * self.vertical - self.origin
    }
}