void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
    vec3 col;
    //Découpage de l'écran en 20 fragments.
    int vingtieme = (int (iResolution.x))/20;
	int largeur = 3; //Largeur voulue des bandes
    
    
    if((int (fragCoord.x)) % vingtieme < largeur) {
        col = vec3(0.0,0.0,0.0);
    	} else {
        col = vec3(1.0,1.0,1.0);
    }
    
    // Output to screen
    fragColor = vec4(col,1.0);
}
