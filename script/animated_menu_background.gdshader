shader_type canvas_item;

uniform float camera_drift : hint_range(0.0, 0.02) = 0.006;
uniform float cloud_motion : hint_range(0.0, 0.03) = 0.009;
uniform float grass_sway : hint_range(0.0, 0.01) = 0.0025;
uniform float water_motion : hint_range(0.0, 0.01) = 0.003;

void fragment() {
	vec2 uv = UV;
	float drift_x = sin(TIME * 0.11) * camera_drift;
	float drift_y = cos(TIME * 0.085) * camera_drift * 0.45;
	uv = (uv - vec2(0.5)) * 0.992 + vec2(0.5) + vec2(drift_x, drift_y);

	vec4 source = texture(TEXTURE, clamp(uv, vec2(0.002), vec2(0.998)));
	float sky_region = 1.0 - smoothstep(0.08, 0.34, uv.y);
	float cloud_tone = smoothstep(0.40, 0.78, dot(source.rgb, vec3(0.299, 0.587, 0.114)));
	float cloud_mask = sky_region * cloud_tone;
	uv.x += cloud_mask * (sin(TIME * 0.17 + uv.y * 15.0) * cloud_motion
		+ sin(TIME * 0.07 + uv.x * 8.0) * cloud_motion * 0.35);

	float green_strength = source.g - max(source.r, source.b * 0.82);
	float grass_region = smoothstep(0.30, 0.52, uv.y);
	float grass_mask = smoothstep(0.025, 0.20, green_strength) * grass_region;
	uv.x += grass_mask * sin(TIME * 1.35 + uv.y * 34.0 + uv.x * 17.0) * grass_sway;
	uv.y += grass_mask * sin(TIME * 0.9 + uv.x * 25.0) * grass_sway * 0.22;

	float blue_strength = source.b - source.r;
	float water_mask = smoothstep(0.025, 0.18, blue_strength) * smoothstep(0.24, 0.55, uv.y);
	uv.x += water_mask * sin(uv.y * 85.0 - TIME * 2.1) * water_motion;
	uv.y += water_mask * sin(uv.x * 70.0 + TIME * 1.45) * water_motion * 0.45;

	vec4 result = texture(TEXTURE, clamp(uv, vec2(0.002), vec2(0.998)));
	float shimmer = (sin((uv.x + uv.y) * 115.0 - TIME * 2.8) * 0.5 + 0.5) * water_mask;
	result.rgb += vec3(0.035, 0.055, 0.065) * shimmer;
	COLOR = result;
}
