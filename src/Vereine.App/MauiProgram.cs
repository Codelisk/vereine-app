#if DEBUG
using Microsoft.Maui.DevFlow.Agent;
using Microsoft.Maui.DevFlow.Blazor;
#endif
using Microsoft.Extensions.Configuration;
using Shiny.Mediator.Http;
using Vereine.App.Infrastructure;

namespace Vereine.App;

public static class MauiProgram
{
    public static MauiApp CreateMauiApp()
    {
        var builder = MauiApp.CreateBuilder();

        // appsettings.json plus appsettings.android.json bzw. appsettings.apple.json (Shiny.Extensions.Configuration)
        builder.Configuration.AddJsonPlatformBundle();

        builder
            .UseMauiApp<App>()
            .UseShiny()
            // Mit dem ersten Handler kommt .AddMediatorRegistry() dazu: der Source Generator erzeugt die
            // Methode erst, wenn es im Projekt Handler mit [MediatorSingleton]/[MediatorScoped] gibt.
            .AddShinyMediator(x => x
                .AddMauiPersistentCache()
                .AddConnectivityBroadcaster()
                .UseBlazor()
            );

        builder.Services.AddMauiBlazorWebView();
        // Kopfzeilen fuer jeden HTTP-Aufruf ueber Shiny Mediator an vereine-api (README, Abschnitt API-Anbindung)
        builder.Services.AddSingleton<IHttpRequestDecorator, AppHttpRequestDecorator>();

#if DEBUG
        builder.Services.AddBlazorWebViewDeveloperTools();
        builder.Logging.SetMinimumLevel(LogLevel.Trace);
        builder.Logging.AddDebug();
        builder.AddMauiDevFlowAgent();
        builder.AddMauiBlazorDevFlowTools();
#endif

        return builder.Build();
    }
}
