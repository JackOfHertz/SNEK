#pragma language glsl3

uniform float time;
uniform Image simplex;
//uniform Image mask;

vec4 effect(
    vec4 color,
    Image tex, 
    vec2 texture_coords,
    vec2 screen_coords)
{
  float noise_width = 64;
  float sprite_width = 64;
  float speed = 0.05 * (sprite_width / noise_width);
  float amp = 0.05;

  vec2 noise_time_index = fract(texture_coords * (sprite_width / noise_width) + vec2(speed * time, -speed * time));
  vec4 noisecolor = Texel(simplex, noise_time_index);
  float xy = noisecolor.b * 0.7071;
  noisecolor.r=(noisecolor.r + xy) / 1.7071;
  noisecolor.g=(noisecolor.g + xy) / 1.7071;
  vec2 displacement = texture_coords + (((amp * 2) * vec2(noisecolor)) - amp);
  //vec4 mask_value = Texel(mask, texture_coords);
  //vec4 mask_value_source = Texel(mask, displacement);
  vec4 texturecolor;
  //if (mask_value.r == 1 && mask_value_source.r == 1) {
  //  texturecolor = Texel(tex, displacement);
  //} else {
  //  texturecolor = Texel(tex, texture_coords);
  //}
  texturecolor = Texel(tex, displacement);
  return texturecolor * color;
}
