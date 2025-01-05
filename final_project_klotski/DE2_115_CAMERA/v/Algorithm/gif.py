import matplotlib.pyplot as plt
import numpy as np
from PIL import Image
import io

def matrix_to_image(matrix):
    # Set up the plot
    plt.figure(figsize=(6, 6))
    plt.axis('off')
    plt.gca().set_facecolor("white")  # Set background to white
    num_rows, num_cols = matrix.shape

    # Plot integer values in each cell with larger font size
    for (i, j), val in np.ndenumerate(matrix):
        plt.text(
            j, (3 - i), int(val),
            ha='center', va='center',
            fontsize=24, color='black'
        )

    # Draw grid lines
    for i in range(num_rows + 1):
        plt.plot([-0.5, num_cols - 0.5], [i - 0.5, i - 0.5], color='black', linewidth=1)
    for j in range(num_cols + 1):
        plt.plot([j - 0.5, j - 0.5], [-0.5, num_rows - 0.5], color='black', linewidth=1)

    # Adjust plot limits to fit the matrix without margins
    plt.xlim(-0.5, num_cols - 0.5)
    plt.ylim(num_rows - 0.5, -0.5)
    plt.gca().invert_yaxis()  # Keep (0,0) at the top-left corner

    # Save plot to an in-memory file
    buf = io.BytesIO()
    plt.savefig(buf, format='png', bbox_inches='tight', pad_inches=0)
    buf.seek(0)
    plt.close()
    
    # Return the in-memory image
    return Image.open(buf)

def write_gif(matrices):
    # Convert each matrix to an image
    images = [matrix_to_image(matrix) for matrix in matrices]
    # Create GIF from the list of images
    images[0].save(
        'matrix_animation.gif', 
        save_all=True, 
        append_images=images[1:], 
        duration=500, 
        loop=0
    )

    print("GIF created as 'matrix_animation.gif'")

def main(matrices):
    write_gif(matrices)

if __name__ == "__main__":
    # Example: Generate a list of matrices to animate
    matrices = [
        np.random.randint(0, 10, (4, 4)),  # Random 4x4 integer matrix
        np.random.randint(0, 10, (4, 4)),
        np.random.randint(0, 10, (4, 4))
        # Add more matrices for a longer animation
    ]
    main(matrices)
