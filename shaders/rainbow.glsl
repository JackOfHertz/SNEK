#pragma language glsl3

extern number time;
vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords)
{
  return vec4((1.0+sin(time))/2.0, abs(cos(time)), abs(sin(time)), 1.0);
}
