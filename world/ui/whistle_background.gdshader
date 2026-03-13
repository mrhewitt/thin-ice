shader_type canvas_item;


void fragment() {
	float percent = 1.0 - step( 0.5, distance(UV,vec2(0.5)) );
	COLOR.a = percent * 0.4;
}
