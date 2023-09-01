# Raymarch Voxels 

Render voxel models in Unity URP by rendering a cube volume and raymarching a 3D texture to display the voxels.

[![WebGL Demo Scene](/Images/DemoScene.png)](https://arlorean.github.io/RaymarchVoxels/)

## Teardown Inspiration

This repository was inspired after watching the excellent [Tuxedo Labs Teardown Technical Teardown](https://www.youtube.com/watch?v=0VzE8ROwC58) stream on YouTube.

![Demo Scene](/Images/Teardown_Key_Art_01.png)

The key takeaways from this video were:
- Store voxels using a 3D Texture
- Render the back faces of a cube (so you can see the voxel model when you're inside the volume)
- Raymarch through the texture to work out which voxel to display

There were other excellent things to note that I've not included in this repository:
- Create a scene axis aligned bitmap (1 bit per voxel) of all voxels for occlusion testing
- Use sphere colliders per voxel and only collide them when the pattern of corners/edges/faces matches up
- Store voxels as a 1 byte index into a 256 color palette (Each model can have its own palette)

## Unity Cookbook

The code used the [Unity URP Cookbook Volumetric cloud rendering](https://www.youtube.com/watch?v=hXYOlXVRRL8) sample Shader Graph as a starting point.

URP was chosen so as to eventually be able to display this in WebGL.

The modified Shader Graph uses the ```View Direction``` node instead of the camera node (I was trying to get shadows to work). The underlying shader calulates the RawDepth (```SV_Depth```) but there is no where to feed it into the URP ```Fragment``` lighting block at the end.

![Shader Graph](/Images/ShaderGraph.png)

## Voxel to 3D Texture

3D Textures in Unity can be created from a single image that is split into a grid of slices, similar to a sprite sheet. The slices are down the Z axis in Unity:

![Slices](/Images/WizardSlices.png)

Here is the original Wizard voxel file so you can see what it looks like in 3D:

![Voxel in 3D](/Images/Wizard.gif)

The [Arlorean/Voxels](https://github.com/Arlorean/Voxels) project command line utility was used to create the 3D textures. Run it with the ```--3D``` command line argument supplying a ```.vox``` Magica Voxel file or a ```.qb``` Qubicle Export File:

```
Voxels.CommandLine.exe --3D Nerds.qb
Voxels.CommandLine.exe --3D chr_knight.vox
```

The import settings for the texture should be set to ```3D```, ```Clamp```, ```Point Filter```, ```No MipMaps```, ```No compression``` and ```Non-Power of 2``` set to ```None```. The ```Columns``` and ```Rows``` specify how the whole image is broken up into a grid of Z slices which are the numbers shown in round brackets on the generated .png file, e.g. ```Nerds.(45x1).png``` for ```45 Columns``` and ```1 Row```:

![Texture Import Settings](/Images/TextureImportSettings.png)

To display in Unity, create a 1x1x1 Cube from the ```Context menu->3D Object->Cube```. Create a new material for the cube and set the shader to be the ```RaymarchShader``` Shader Graph and the 3D Texture to be the imported ```Nerds.(45x1).png``` sliced image. Then scale that cube so the aspect ratio matches the x/y/z dimensions of the 3D Texture. In this case above, the Nerds model is ```48x44x45``` so an example scale shown below would be ```4.8x4.4x4.5``` where ```0.1``` units (meters) represents 1 voxel:

![Cube Transform Scale](/Images/CubeTransform.png)

Unity version ```2023.1.7f1``` was used to create this repository.

## Problems

URP Shader Graph doesn't have the ability to override the depth (```SV_DEPTH```) of a fragment which means the depth of every pixel is just the depth of the back face of the rendered cube. This has implications for things like screen space effects that rely on the depth map being correct.

![Default Depth Buffer](/Images/DefaultCubeDepth.png)

The only way around this would be to create a shader by hand in URP but then we would lose all the built-in lighting effects provided by the URP Fragment block. I did try coping the generated shader code and adding in the depth by it was fragile. Here is the depth buffer from the Unity Frame Debugger showing it working:

![Correct Depth Buffer](/Images/SV_DEPTH.png)

HDRP seemed to show strange artifacts when rendering with warped edges of the volume:

![HDRP Warping](/Images/HDRP.png)

Shadows don't seem to work properly, although I've just read that it's because the shadow map is rendered using an orthographic camera and the code doesn't currently support that.

![Incorrect Shadows](/Images/Shadows.png)

Unity doesn't like imported textures to be too wide (or high) so if the sliced image is very long, because it can't be divided into a grid easily, then you won't be able to display it. The workaround is to make the model larger in the front to back axis (Y in MagicaVoxel, Z in Unity), so that that depth is a power of 2 or can be divided to make a roughly even grid.

## Credits

[A Fast Voxel Traversal Algorithm for Ray Tracing](http://www.cse.yorku.ca/~amana/research/grid.pdf) by John Amanatides and Andrew Woo (August 1987).

[Qubicle](https://store.steampowered.com/app/454550/Qubicle_Voxel_Editor/) demo Nerds model.

[MagicaVoxel](https://ephtracy.github.io/) sample voxel models.

[3D Voxel Office Pack](https://mariaisme.itch.io/3d-voxel-office) by [MarialsMe](https://mariaisme.itch.io/).

[Akamai-Community](https://github.com/Akamai-Community/inspiring-game-scenes) Desktop-sample scene.


