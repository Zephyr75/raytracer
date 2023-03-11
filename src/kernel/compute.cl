struct vec3 {
  float x;
  float y;
  float z;
};

typedef struct vec3 vec3;

vec3 vec3_add(vec3 a, vec3 b) {
  vec3 result;
  result.x = a.x + b.x;
  result.y = a.y + b.y;
  result.z = a.z + b.z;
  return result;
}

vec3 vec3_sub(vec3 a, vec3 b) {
  vec3 result;
  result.x = a.x - b.x;
  result.y = a.y - b.y;
  result.z = a.z - b.z;
  return result;
}

vec3 vec3_mul(vec3 a, vec3 b) {
  vec3 result;
  result.x = a.x * b.x;
  result.y = a.y * b.y;
  result.z = a.z * b.z;
  return result;
}

vec3 vec3_div(vec3 a, vec3 b) {
  vec3 result;
  result.x = a.x / b.x;
  result.y = a.y / b.y;
  result.z = a.z / b.z;
  return result;
}

vec3 vec3_scale(vec3 a, float b) {
  vec3 result;
  result.x = a.x * b;
  result.y = a.y * b;
  result.z = a.z * b;
  return result;
}

vec3 vec3_unit(vec3 a) {
  float length = sqrt(a.x * a.x + a.y * a.y + a.z * a.z);
  vec3 result;
  result.x = a.x / length;
  result.y = a.y / length;
  result.z = a.z / length;
  return result;
}

vec3 vec3_new(float x, float y, float z) {
  vec3 result;
  result.x = x;
  result.y = y;
  result.z = z;
  return result;
}

float vec3_dot(vec3 a, vec3 b) { return a.x * b.x + a.y * b.y + a.z * b.z; }

struct color {
  float r;
  float g;
  float b;
};

typedef struct color color;

struct ray {
  vec3 origin;
  vec3 direction;
};

typedef struct ray ray;

////////////////////////////////////////
////////////////////////////////////////

bool hit_sphere(vec3 center, float radius, ray r) {
  vec3 oc = vec3_sub(r.origin, center);
  float a = vec3_dot(r.direction, r.direction);
  float b = 2.0 * vec3_dot(oc, r.direction);
  float c = vec3_dot(oc, oc) - radius * radius;
  float discriminant = b * b - 4 * a * c;
  return (discriminant > 0);
}

vec3 ray_color(ray r) {
  if (hit_sphere(vec3_new(0.0, 0.0, -1.0), 0.5, r)) {
    return vec3_new(1.0, 0.0, 0.0);
  }
  vec3 unit_direction = vec3_unit(r.direction);
  float t = 0.5 * (unit_direction.y + 1.0);
  vec3 v1 = vec3_add(vec3_scale(vec3_new(1.0, 1.0, 1.0), 1.0 - t),
                     vec3_scale(vec3_new(0.5, 0.7, 1.0), t));
  return v1;
}

__kernel void compute(__global int *array, int width, int height) {
  int x = get_global_id(0);
  int y = get_global_id(1);

  float viewport_height = 2.0;
  float aspect_ratio = 16.0 / 9.0;
  float viewport_width = aspect_ratio * viewport_height;
  float focal_length = 1.0;

  vec3 origin = vec3_new(0.0, 0.0, 0.0);
  vec3 horizontal = vec3_new(viewport_width, 0.0, 0.0);
  vec3 vertical = vec3_new(0.0, viewport_height, 0.0);

  vec3 lower_left_corner = vec3_sub(
      vec3_sub(origin, vec3_scale(horizontal, 0.5)), vec3_scale(vertical, 0.5));

  float u = (float)x / (float)width;
  float v = (float)y / (float)height;

  ray r1;
  r1.origin = vec3_new(0.0, 0.0, 0.0);
  r1.direction = vec3_sub(
      vec3_sub(vec3_add(vec3_add(lower_left_corner, vec3_scale(horizontal, u)),
                        vec3_scale(vertical, v)),
               origin),
      vec3_new(0.0, 0.0, focal_length));

  vec3 color = ray_color(r1);

  int r = (int)(255 * color.x);
  int g = (int)(255 * color.y);
  int b = (int)(255 * color.z);
  int a = 255;

  int color2 = (a << 24) | (b << 16) | (g << 8) | r;
  array[(height - y - 1) * width + x] = color2;
}