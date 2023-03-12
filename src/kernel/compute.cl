double degrees_to_radians(double degrees) { return degrees * M_PI / 180.0; }


typedef struct {
  float r;
  float g;
  float b;
} color;

////////////////////////////////////////

typedef struct {
  float3 origin;
  float3 direction;
} ray;
float3 at(ray r, float t) { return r.origin + r.direction * t; }

////////////////////////////////////////

typedef struct {
  float t;
  float3 p;
  float3 normal;
  bool front_face;
} hit_record;
void set_face_normal(hit_record *rec, ray r, float3 outward_normal) {
  rec->front_face = dot(r.direction, outward_normal) < 0;
  rec->normal = rec->front_face ? outward_normal : -outward_normal;
}

////////////////////////////////////////

typedef struct {
  float3 center;
  float radius;
} sphere;

bool hit(sphere s, ray r, float t_min, float t_max, hit_record *rec) {
  float3 oc = r.origin - s.center;
  float a = pow(length(r.direction), 2);
  float half_b = dot(oc, r.direction);
  float c = pow(length(oc), 2) - pow(s.radius, 2);
  float discriminant = pow(half_b, 2) - a * c;
  if (discriminant < 0) {
    return false;
  }
  float sqrtd = sqrt(discriminant);
  // Find the nearest root that lies in the acceptable range.
  float root = (-half_b - sqrtd) / a;
  if (root < t_min || t_max < root) {
    root = (-half_b + sqrtd) / a;
    if (root < t_min || t_max < root) {
      return false;
    }
  }
  rec->t = root;
  rec->p = at(r, rec->t);
  rec->normal = (rec->p - s.center) / s.radius;
  float3 outward_normal = (rec->p - s.center) / s.radius;
  set_face_normal(rec, r, outward_normal);
  return true;
}

bool hit_anything(sphere *spheres, int spheres_size, ray r, float t_min,
                  float t_max, hit_record *rec) {
  hit_record temp_rec;
  bool hit_anything = false;
  double closest_so_far = t_max;
  for (int i = 0; i < spheres_size; i++) {
    if (hit(spheres[i], r, t_min, closest_so_far, &temp_rec)) {
      hit_anything = true;
      closest_so_far = temp_rec.t;
      *rec = temp_rec;
    }
  }
  return hit_anything;
}

////////////////////////////////////////

typedef struct {
  float3 origin;
  float3 lower_left_corner;
  float3 horizontal;
  float3 vertical;
} camera;

camera camera_new() {
  float aspect_ratio = 16.0 / 9.0;
  float viewport_height = 2.0;
  float viewport_width = aspect_ratio * viewport_height;
  float focal_length = 1.0;
  float3 origin = (float3)(0.0);
  float3 horizontal = (float3)(viewport_width, 0.0, 0.0);
  float3 vertical = (float3)(0.0, viewport_height, 0.0);
  float3 lower_left_corner =
      origin - horizontal / 2 - vertical / 2 - (float3)(0.0, 0.0, focal_length);
  camera c;
  c.origin = origin;
  c.lower_left_corner = lower_left_corner;
  c.horizontal = horizontal;
  c.vertical = vertical;
  return c;
}

ray get_ray(camera c, float u, float v) {
  ray r;
  r.origin = c.origin;
  r.direction = c.lower_left_corner + c.horizontal * u + c.vertical * v -
                c.origin;
  return r;
}


////////////////////////////////////////
////////////////////////////////////////

float3 ray_color(ray r, sphere *spheres, int spheres_size) {
  hit_record rec;
  if (hit_anything(spheres, spheres_size, r, 0.001, INFINITY, &rec)) {
    return (rec.normal + 1) * (float3)(0.5);
  }

  float3 unit_direction = normalize(r.direction);
  float t = 0.5 * (unit_direction.y + 1.0);
  return (float3)(1.0 - t) * (float3)(1.0) + t * (float3)(0.5, 0.7, 1.0);
}

////////////////////////////////////////

__kernel void compute(__global int *array, int width, int height) {
  int x = get_global_id(0);
  int y = get_global_id(1);

  float u = (float)x / (float)width;
  float v = (float)y / (float)height;


  sphere spheres[2];
  spheres[0].center = (float3)(0.0, 0.0, -1.0);
  spheres[0].radius = 0.5;
  spheres[1].center = (float3)(0.0, -100.5, -1.0);
  spheres[1].radius = 100;
  int spheres_size = 2;

  camera cam = camera_new();
  
  ray r1 = get_ray(cam, u, v);

  float3 color = ray_color(r1, spheres, spheres_size);

  int r = (int)(255 * color.x);
  int g = (int)(255 * color.y);
  int b = (int)(255 * color.z);
  int a = 255;

  int color2 = (a << 24) | (b << 16) | (g << 8) | r;
  array[(height - y - 1) * width + x] = color2;
}