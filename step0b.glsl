void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec2 centre = iResolution.xy/2.0;
	
    int largeur = 3;
    int freqRayon = 20;
    float distance = sqrt(pow(fragCoord.x-centre.x,2.0) + pow(fragCoord.y-centre.y,2.0));
    
    vec3 col;
    
    if(int (distance)%freqRayon < largeur) {
        col = vec3(0.0,0.0,0.0);
    } else {
        col = vec3(1.0,1.0,1.0);
    }
    
    // Output to screen
    fragColor = vec4(col,1.0);
}
