namespace Vereine.App;

public partial class App : Application
{
    public App()
    {
        InitializeComponent();
    }

    // Blazor Hybrid: ein Fenster mit genau einer Seite, die Navigation macht der Blazor-Router.
    protected override Window CreateWindow(IActivationState? activationState) => new(new MainPage());
}
