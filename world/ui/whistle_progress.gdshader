shader_type canvas_item;

uniform float progress : hint_range(0.0,1.0) = 1.0f;

void fragment() {
	COLOR.a *= step( 1.0 - progress, UV.y ) + 0.1;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
