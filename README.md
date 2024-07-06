# Hungry

![IMG_0436](https://github.com/rodneyg/Hungry/assets/6868495/b1aff753-71ee-4778-910e-21789176e399)

Hungry is a SwiftUI-based iOS application that helps users create recipes based on ingredients they have in their kitchen. The app uses computer vision and natural language processing to identify ingredients from photos and generate suitable recipes.

## Features

- **Image Capture**: Users can take photos of their kitchen or ingredients.
- **Ingredient Recognition**: The app uses OpenAI's Vision API to identify ingredients in the captured images.
- **Recipe Generation**: Based on identified ingredients, the app generates recipes using OpenAI's GPT-4.
- **Ingredient Management**: Users can manually add, edit, or remove ingredients from the identified list.
- **Recipe Saving**: Favorite recipes can be saved for quick access later.
- **Recipe Filtering**: Users can filter recipes based on dietary preferences (All, Vegetarian, Vegan, Gluten-Free).
- **Detailed Recipe View**: Each recipe includes name, ingredients, instructions, preparation time, and required appliances.

## Requirements

- iOS 14.0+
- Xcode 12.0+
- Swift 5.3+
- OpenAI API Key

## Installation

Clone this repository:

```bash
git clone https://github.com/yourusername/kitchen-assistant.git
```

Open the project in Xcode:

```bash
cd kitchen-assistant
open KitchenAssistant.xcodeproj
```

Install dependencies using Swift Package Manager:
1. In Xcode, go to `File > Swift Packages > Add Package Dependency`.
2. Enter the URL: `https://github.com/MacPaw/OpenAI.git`.

Add your OpenAI API key:
1. In `ContentView.swift`, replace `"YOUR_API_KEY_HERE"` with your actual OpenAI API key.

Build and run the project in Xcode.

## Usage

1. Launch the app and tap the camera button to take photos of your kitchen or ingredients.
2. After capturing images, tap "Process Images" to identify ingredients.
3. Review and edit the identified ingredients if necessary.
4. The app will generate recipe suggestions based on the ingredients.
5. Use the dietary filter to narrow down recipe options.
6. Tap on a recipe to view details, including ingredients, instructions, and required appliances.
7. Save favorite recipes for future reference.

## Architecture

The app follows a simple MVVM (Model-View-ViewModel) architecture:

- **Models**: `Recipe` struct
- **Views**: `ContentView`, `RecipeDetailView`, `RecipeRowView`, `IngredientManagementView`, `SavedRecipesView`
- **ViewModels**: The logic is currently in `ContentView`, but could be refactored into a separate ViewModel for better separation of concerns.

## Dependencies

- **OpenAI Swift**: For interacting with OpenAI's API

## Future Improvements

- Implement local storage (Core Data or UserDefaults) for saved recipes.
- Add unit tests and UI tests.
- Implement error handling and retry mechanisms for API calls.
- Add a shopping list feature for missing ingredients.
- Implement portion adjustment for recipes.
- Add more advanced filtering and sorting options.
- Implement user accounts and cloud syncing for saved recipes.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE.md](LICENSE.md) file for details.

## Acknowledgments

- **OpenAI** for providing the API for ingredient recognition and recipe generation.
- The SwiftUI community for inspiration and resources.
