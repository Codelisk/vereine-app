using Shiny.Mediator.Http;

namespace Vereine.App.Infrastructure;

/// <summary>
/// Ergaenzt jeden HTTP-Aufruf, den Shiny Mediator an vereine-api schickt, um App-Version, Geraet,
/// Sprache und Zeitzone. Die Anmeldung (Bearer-Token) kommt hierher, sobald es sie gibt.
/// </summary>
public sealed class AppHttpRequestDecorator(IPlatform platform) : IHttpRequestDecorator
{
    public Task Decorate(HttpRequestMessage httpMessage, IMediatorContext context, CancellationToken cancellationToken)
    {
        httpMessage.Headers.UserAgent.ParseAdd($"{platform.ApplicationIdentifier ?? "vereine"}/{platform.AppVersion} ({platform.Platform}; {platform.DeviceModel}; {platform.DeviceManufacturer})");
        httpMessage.Headers.Add("X-Device-Locale", platform.CurrentCulture.Name);
        httpMessage.Headers.Add("X-Device-Timezone", platform.CurrentTimeZone.Id);

        return Task.CompletedTask;
    }
}
