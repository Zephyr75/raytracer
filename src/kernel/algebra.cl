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

float vec3_dot(vec3 a, vec3 b) {
    return a.x * b.x + a.y * b.y + a.z * b.z;
}

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
