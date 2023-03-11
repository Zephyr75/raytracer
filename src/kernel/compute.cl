

struct color {
  float r;
  float g;
  float b;
};

typedef struct color color;

struct ray {
  float3 origin;
  float3 direction;
};

typedef struct ray ray;

float3 ray_pointAt(ray r, float t) {
  return r.origin + r.direction * t;
}

////////////////////////////////////////
////////////////////////////////////////

double hit_sphere(float3 center, float radius, ray r) {
  float3 oc = r.origin - center;
  float a = pow(length(r.direction), 2);
  float half_b = dot(oc, r.direction);
  float c = pow(length(oc), 2) - pow(radius, 2);
  float discriminant = pow(half_b, 2) - a * c;
    if (discriminant < 0) {
    return -1.0;
    } else {
        return (-half_b - sqrt(discriminant)) / a;
    }
}

float3 ray_color(ray r) {
  double t = hit_sphere((float3)(0.0, 0.0, -1.0), 0.5, r);
    if (t > 0.0) {
        float3 N = normalize(ray_pointAt(r, t) - (float3)(0.0, 0.0, -1.0));
        return (N + (float3)(1.0)) * (float3)(0.5);
    }


  float3 unit_direction = normalize(r.direction);
  t = 0.5 * (unit_direction.y + 1.0);
  float3 v1 = (float3)(1.0, 1.0, 1.0) * (float3)(1.0 - t) +
              (float3)(0.5, 0.7, 1.0) * (float3)(t);
  return v1;
}

__kernel void compute(__global int *array, int width, int height) {
  int x = get_global_id(0);
  int y = get_global_id(1);

  float viewport_height = 2.0;
  float aspect_ratio = 16.0 / 9.0;
  float viewport_width = aspect_ratio * viewport_height;
  float focal_length = 1.0;

  float3 origin = (float3)(0.0);
  float3 horizontal = (float3)(viewport_width, 0.0, 0.0);
  float3 vertical = (float3)(0.0, viewport_height, 0.0);

  float3 lower_left_corner = origin - horizontal / 2 - vertical / 2 - (float3)(0.0, 0.0, focal_length);

  float u = (float)x / (float)width;
  float v = (float)y / (float)height;

  ray r1;
  r1.origin = (float3)(0.0);
  r1.direction = lower_left_corner + horizontal * u + vertical * v - origin;
  

  float3 color = ray_color(r1);

  int r = (int)(255 * color.x);
  int g = (int)(255 * color.y);
  int b = (int)(255 * color.z);
  int a = 255;

  int color2 = (a << 24) | (b << 16) | (g << 8) | r;
  array[(height - y - 1) * width + x] = color2;
}