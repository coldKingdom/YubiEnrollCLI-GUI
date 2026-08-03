#requires -Version 7.0

[CmdletBinding()]
param(
    [switch]$SelfTest
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# WPF requires an STA thread. Relaunch transparently when the script was started
# from a regular PowerShell 7 console (which may use MTA).
if ([System.Threading.Thread]::CurrentThread.ApartmentState -ne 'STA') {
    $hostExecutable = (Get-Process -Id $PID).Path
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $hostExecutable
    $startInfo.UseShellExecute = $true
    $relaunchArguments = @('-NoLogo', '-NoProfile', '-STA', '-File', $PSCommandPath)
    if ($SelfTest) { $relaunchArguments += '-SelfTest' }
    foreach ($argument in $relaunchArguments) {
        [void]$startInfo.ArgumentList.Add($argument)
    }
    [void][System.Diagnostics.Process]::Start($startInfo)
    return
}

Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase

$xaml = @'
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="YubiEnroll" Width="1120" Height="820" MinWidth="960" MinHeight="700"
        WindowStartupLocation="CenterScreen" Background="#F3F5F8"
        FontFamily="Segoe UI" FontSize="13">
    <Window.Resources>
        <SolidColorBrush x:Key="AccentBrush" Color="#2458A6"/>
        <SolidColorBrush x:Key="AccentHoverBrush" Color="#1D4787"/>
        <SolidColorBrush x:Key="DangerBrush" Color="#B42318"/>
        <SolidColorBrush x:Key="BorderBrush" Color="#D8DEE8"/>
        <Style TargetType="Button">
            <Setter Property="Width" Value="176"/>
            <Setter Property="Height" Value="38"/>
            <Setter Property="Padding" Value="14,6"/>
            <Setter Property="Margin" Value="0,0,8,8"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="HorizontalContentAlignment" Value="Center"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style x:Key="PrimaryButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="{StaticResource AccentBrush}"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderBrush" Value="{StaticResource AccentBrush}"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
        <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="White"/>
            <Setter Property="Foreground" Value="{StaticResource DangerBrush}"/>
            <Setter Property="BorderBrush" Value="#E6A6A1"/>
        </Style>
        <Style x:Key="BrowseButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Width" Value="112"/>
        </Style>
        <Style x:Key="CompactButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Width" Value="78"/>
            <Setter Property="Height" Value="28"/>
            <Setter Property="Padding" Value="8,2"/>
            <Setter Property="Margin" Value="0,0,6,0"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="MinHeight" Value="32"/>
            <Setter Property="Padding" Value="7,5"/>
            <Setter Property="Margin" Value="0,3,8,9"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="MinHeight" Value="32"/>
            <Setter Property="Padding" Value="5,3"/>
            <Setter Property="Margin" Value="0,3,8,9"/>
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="ComboBoxItem">
            <Setter Property="HorizontalContentAlignment" Value="Left"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Margin" Value="0,7,14,9"/>
            <Setter Property="VerticalAlignment" Value="Center"/>
        </Style>
        <Style TargetType="GroupBox">
            <Setter Property="Background" Value="White"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
            <Setter Property="Padding" Value="14"/>
            <Setter Property="Margin" Value="0,0,0,14"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="Padding" Value="0,4,0,0"/>
            <Setter Property="Foreground" Value="#344054"/>
        </Style>
        <Style TargetType="TabItem">
            <Setter Property="Padding" Value="18,10"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
        </Style>
        <Style TargetType="DataGrid">
            <Setter Property="Background" Value="White"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
            <Setter Property="GridLinesVisibility" Value="Horizontal"/>
            <Setter Property="HorizontalGridLinesBrush" Value="#EAECF0"/>
            <Setter Property="RowHeight" Value="34"/>
            <Setter Property="HeadersVisibility" Value="Column"/>
            <Setter Property="CanUserAddRows" Value="False"/>
            <Setter Property="CanUserDeleteRows" Value="False"/>
            <Setter Property="IsReadOnly" Value="True"/>
            <Setter Property="SelectionMode" Value="Single"/>
            <Setter Property="AutoGenerateColumns" Value="True"/>
        </Style>
        <Style x:Key="StatusCard" TargetType="Border">
            <Setter Property="Background" Value="White"/>
            <Setter Property="BorderBrush" Value="{StaticResource BorderBrush}"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="CornerRadius" Value="6"/>
            <Setter Property="Padding" Value="15"/>
            <Setter Property="Margin" Value="0,0,12,12"/>
            <Setter Property="MinHeight" Value="92"/>
        </Style>
        <Style x:Key="HintText" TargetType="TextBlock">
            <Setter Property="Foreground" Value="#667085"/>
            <Setter Property="TextWrapping" Value="Wrap"/>
        </Style>
    </Window.Resources>

    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Border Grid.Row="0" Background="#152B4F" Padding="22,15">
            <DockPanel LastChildFill="False">
                <StackPanel DockPanel.Dock="Left">
                    <TextBlock Text="YubiEnroll" Foreground="White" FontSize="25" FontWeight="SemiBold"/>
                    <TextBlock Text="Administrera användare, FIDO-credentials och konfigurationer" Foreground="#C9D6EA" Margin="0,3,0,0"/>
                </StackPanel>
                <Border DockPanel.Dock="Right" Background="#223F6D" CornerRadius="5" Padding="12,7" VerticalAlignment="Center">
                    <TextBlock x:Name="VersionText" Text="Kontrollerar version..." Foreground="White"/>
                </Border>
            </DockPanel>
        </Border>

        <TabControl x:Name="MainTabs" Grid.Row="1" Margin="16,12,16,8">
            <TabItem Header="Start">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="4,14,4,4">
                        <TextBlock Text="Systemöversikt" FontSize="22" FontWeight="SemiBold" Foreground="#101828" Margin="0,0,0,12"/>
                        <UniformGrid Columns="4">
                            <Border Style="{StaticResource StatusCard}"><StackPanel><TextBlock Text="AKTIV PROVIDER" Foreground="#667085" FontSize="11" FontWeight="SemiBold"/><TextBlock x:Name="ActiveProviderValue" Text="Ej kontrollerad" FontSize="17" FontWeight="SemiBold" Margin="0,9,0,0" TextWrapping="Wrap"/></StackPanel></Border>
                            <Border Style="{StaticResource StatusCard}"><StackPanel><TextBlock Text="INLOGGNING" Foreground="#667085" FontSize="11" FontWeight="SemiBold"/><TextBlock x:Name="LoginStatusValue" Text="Ej kontrollerad" FontSize="17" FontWeight="SemiBold" Margin="0,9,0,0" TextWrapping="Wrap"/></StackPanel></Border>
                            <Border Style="{StaticResource StatusCard}"><StackPanel><TextBlock Text="NFC-LÄSARE" Foreground="#667085" FontSize="11" FontWeight="SemiBold"/><TextBlock x:Name="ReaderStatusValue" Text="Ej kontrollerad" FontSize="17" FontWeight="SemiBold" Margin="0,9,0,0" TextWrapping="Wrap"/></StackPanel></Border>
                            <Border Style="{StaticResource StatusCard}"><StackPanel><TextBlock Text="VALD ANVÄNDARE" Foreground="#667085" FontSize="11" FontWeight="SemiBold"/><TextBlock x:Name="SelectedUserValue" Text="Ingen vald" FontSize="17" FontWeight="SemiBold" Margin="0,9,0,0" TextWrapping="Wrap"/></StackPanel></Border>
                        </UniformGrid>
                        <GroupBox Header="Snabbåtgärder">
                            <StackPanel>
                                <TextBlock Style="{StaticResource HintText}" Margin="0,0,0,13" Text="Uppdatera status innan du registrerar en säkerhetsnyckel."/>
                                <WrapPanel>
                                    <Button x:Name="StatusButton" Content="Uppdatera status" Style="{StaticResource PrimaryButton}"/>
                                    <Button x:Name="ReadersButton" Content="Kontrollera läsare"/>
                                    <Button x:Name="LoginButton" Content="Logga in  ↗" ToolTip="Öppnas i en interaktiv terminal"/>
                                    <Button x:Name="LogoutButton" Content="Logga ut"/>
                                </WrapPanel>
                                <CheckBox x:Name="NoLaunchBrowserCheck" Content="Starta inte webbläsaren automatiskt vid inloggning"/>
                            </StackPanel>
                        </GroupBox>
                        <GroupBox Header="Kom igång">
                            <Grid>
                                <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                                <StackPanel Grid.Column="0" Margin="0,0,20,0"><TextBlock Text="1  Sök användare" FontWeight="SemiBold" FontSize="15"/><TextBlock Style="{StaticResource HintText}" Margin="0,6,0,0" Text="Öppna Registrera nyckel och välj rätt användare i sökresultatet."/></StackPanel>
                                <StackPanel Grid.Column="1" Margin="0,0,20,0"><TextBlock Text="2  Välj policy" FontWeight="SemiBold" FontSize="15"/><TextBlock Style="{StaticResource HintText}" Margin="0,6,0,0" Text="Använd en profil eller öppna avancerade inställningar för en engångskonfiguration."/></StackPanel>
                                <StackPanel Grid.Column="2"><TextBlock Text="3  Registrera" FontWeight="SemiBold" FontSize="15"/><TextBlock Style="{StaticResource HintText}" Margin="0,6,0,0" Text="Det interaktiva säkerhetsflödet öppnas i en terminal och guidar dig vidare."/></StackPanel>
                            </Grid>
                        </GroupBox>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="Registrera nyckel">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="4,14,4,4">
                        <GroupBox Header="1. Sök och välj användare">
                            <StackPanel>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition Width="Auto"/></Grid.ColumnDefinitions>
                                    <StackPanel Grid.Column="0"><Label Content="Namn, användarnamn eller e-post (tomt visar alla)"/><TextBox x:Name="UserQueryText"/></StackPanel>
                                    <Button x:Name="SearchUsersButton" Grid.Column="1" Content="Sök användare" Style="{StaticResource PrimaryButton}" VerticalAlignment="Bottom" Margin="0,0,0,9"/>
                                </Grid>
                                <DataGrid x:Name="UserResultsGrid" Height="170" Margin="0,4,0,8"/>
                                <TextBlock Style="{StaticResource HintText}" Text="Markera en rad för att välja användaren. Om tabellen inte kan tolkas kan ID eller användarnamn anges manuellt nedan."/>
                            </StackPanel>
                        </GroupBox>

                        <GroupBox Header="2. Kontrollera användare och befintliga credentials">
                            <StackPanel>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                                    <StackPanel Grid.Column="0" Margin="0,0,8,0"><Label Content="Användar-ID eller användarnamn"/><TextBox x:Name="CredentialUserText"/></StackPanel>
                                    <StackPanel Grid.Column="1"><Label Content="Credential-ID:n, separerade med mellanslag"/><TextBox x:Name="CredentialIdsText"/></StackPanel>
                                </Grid>
                                <WrapPanel>
                                    <Button x:Name="ListCredentialsButton" Content="Lista credentials"/>
                                    <Button x:Name="DeleteCredentialsButton" Content="Radera markerade" Style="{StaticResource DangerButton}"/>
                                    <CheckBox x:Name="ForceCredentialDeleteCheck" Content="Hoppa över CLI-bekräftelse (--force)"/>
                                </WrapPanel>
                                <DataGrid x:Name="CredentialResultsGrid" Height="145" Margin="0,4,0,0" SelectionMode="Extended"/>
                            </StackPanel>
                        </GroupBox>

                        <GroupBox Header="3. Välj profil och nyckel">
                            <StackPanel>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                                    <StackPanel Grid.Column="0" Margin="0,0,8,0"><Label Content="Enrollment-profil"/><TextBox x:Name="EnrollProfileText"/></StackPanel>
                                    <StackPanel Grid.Column="1" Margin="0,0,8,0"><Label Content="NFC-läsare"/><TextBox x:Name="EnrollReaderText"/></StackPanel>
                                    <StackPanel Grid.Column="2"><Label Content="Visningsnamn för säkerhetsnyckeln"/><TextBox x:Name="EnrollDisplayNameText"/></StackPanel>
                                </Grid>
                                <Expander x:Name="EnrollAdvancedExpander" Header="Avancerade FIDO-inställningar" IsExpanded="False" Margin="0,6,0,12">
                                    <Border Background="#F8FAFC" BorderBrush="{StaticResource BorderBrush}" BorderThickness="1" Padding="14" Margin="0,8,0,0">
                                        <StackPanel>
                                            <TextBlock Style="{StaticResource HintText}" Margin="0,0,0,10" Text="Ärv standard skickar inget argument. På och Av åsidosätter profilens eller providerns standardvärde."/>
                                            <Grid>
                                                <Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                                                <StackPanel Grid.Column="0" Margin="0,0,8,0">
                                                    <Label Content="Minsta PIN-längd (4–63)"/><TextBox x:Name="EnrollMinPinText"/>
                                                    <Label Content="Always UV" ToolTip="Kräver användarverifiering vid varje autentisering."/><ComboBox x:Name="EnrollAlwaysUvCombo"><ComboBoxItem Content="Ärv standard" IsSelected="True"/><ComboBoxItem Content="På"/><ComboBoxItem Content="Av"/></ComboBox>
                                                </StackPanel>
                                                <StackPanel Grid.Column="1" Margin="0,0,8,0">
                                                    <Label Content="Slumpmässig PIN"/><ComboBox x:Name="EnrollRandomPinCombo"><ComboBoxItem Content="Ärv standard" IsSelected="True"/><ComboBoxItem Content="På"/><ComboBoxItem Content="Av"/></ComboBox>
                                                    <Label Content="Slumpmässig PIN-längd (4–63)"/><TextBox x:Name="EnrollRandomPinLengthText" IsEnabled="False"/>
                                                </StackPanel>
                                                <StackPanel Grid.Column="2">
                                                    <Label Content="Enterprise Attestation" ToolTip="Tillåter att providern identifierar den fysiska nyckeln vid registrering."/><ComboBox x:Name="EnrollEaCombo"><ComboBoxItem Content="Ärv standard" IsSelected="True"/><ComboBoxItem Content="På"/><ComboBoxItem Content="Av"/></ComboBox>
                                                    <Label Content="Tvinga PIN-byte"/><ComboBox x:Name="EnrollForcePinCombo"><ComboBoxItem Content="Ärv standard" IsSelected="True"/><ComboBoxItem Content="På"/><ComboBoxItem Content="Av"/></ComboBox>
                                                </StackPanel>
                                            </Grid>
                                            <WrapPanel><Label Content="Återställ nyckeln" Margin="0,2,8,0"/><ComboBox x:Name="EnrollResetCombo" Width="160"><ComboBoxItem Content="Ärv standard" IsSelected="True"/><ComboBoxItem Content="På"/><ComboBoxItem Content="Av"/></ComboBox></WrapPanel>
                                        </StackPanel>
                                    </Border>
                                </Expander>
                            </StackPanel>
                        </GroupBox>

                        <GroupBox Header="4. Granska och registrera">
                            <StackPanel>
                                <TextBlock x:Name="EnrollmentSummaryText" Style="{StaticResource HintText}" Margin="0,0,0,10" Text="Välj en användare och en profil eller egna inställningar."/>
                                <WrapPanel>
                                    <Button x:Name="EnrollButton" Content="Registrera nyckel  ↗" Style="{StaticResource PrimaryButton}" ToolTip="Öppnas i en interaktiv terminal"/>
                                    <CheckBox x:Name="EnrollForceCheck" Content="Hoppa över CLI-bekräftelse (--force)"/>
                                </WrapPanel>
                                <TextBlock Style="{StaticResource HintText}" Text="Öppnas i terminal eftersom YubiEnroll kan begära PIN, fysisk beröring och andra interaktiva svar."/>
                            </StackPanel>
                        </GroupBox>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>

            <TabItem Header="Profiler">
                <Grid Margin="4,14,4,4">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="38*"/><ColumnDefinition Width="12"/><ColumnDefinition Width="62*"/></Grid.ColumnDefinitions>
                    <GroupBox Grid.Column="0" Header="Enrollment-profiler">
                        <Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                            <Button x:Name="ListProfilesButton" Content="Uppdatera lista" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Left"/>
                            <DataGrid x:Name="ProfilesGrid" Grid.Row="1" Margin="0,4,0,0"/>
                        </Grid>
                    </GroupBox>
                    <ScrollViewer Grid.Column="2" VerticalScrollBarVisibility="Auto">
                        <StackPanel>
                            <GroupBox Header="Profilinformation">
                                <StackPanel>
                                    <TextBlock Style="{StaticResource HintText}" Margin="0,0,0,8" Text="Markera en profil till vänster eller ange ett nytt namn."/>
                                    <Label Content="Profilnamn"/><TextBox x:Name="ProfileNameText"/>
                                    <Expander x:Name="ProfileAdvancedExpander" Header="Policyinställningar" IsExpanded="True" Margin="0,4,0,12">
                                        <StackPanel Margin="0,8,0,0">
                                            <Grid><Grid.ColumnDefinitions><ColumnDefinition/><ColumnDefinition/></Grid.ColumnDefinitions>
                                                <StackPanel Grid.Column="0" Margin="0,0,8,0">
                                                    <Label Content="Minsta PIN-längd (4–63)"/><TextBox x:Name="ProfileMinPinText"/>
                                                    <Label Content="Always UV"/><ComboBox x:Name="ProfileAlwaysUvCombo"><ComboBoxItem Content="Ärv standard" IsSelected="True"/><ComboBoxItem Content="På"/><ComboBoxItem Content="Av"/></ComboBox>
                                                    <Label Content="Enterprise Attestation"/><ComboBox x:Name="ProfileEaCombo"><ComboBoxItem Content="Ärv standard" IsSelected="True"/><ComboBoxItem Content="På"/><ComboBoxItem Content="Av"/></ComboBox>
                                                </StackPanel>
                                                <StackPanel Grid.Column="1">
                                                    <Label Content="Slumpmässig PIN"/><ComboBox x:Name="ProfileRandomPinCombo"><ComboBoxItem Content="Ärv standard" IsSelected="True"/><ComboBoxItem Content="På"/><ComboBoxItem Content="Av"/></ComboBox>
                                                    <Label Content="Slumpmässig PIN-längd (4–63)"/><TextBox x:Name="ProfileRandomPinLengthText" IsEnabled="False"/>
                                                    <Label Content="Tvinga PIN-byte"/><ComboBox x:Name="ProfileForcePinCombo"><ComboBoxItem Content="Ärv standard" IsSelected="True"/><ComboBoxItem Content="På"/><ComboBoxItem Content="Av"/></ComboBox>
                                                </StackPanel>
                                            </Grid>
                                            <WrapPanel><Label Content="Återställ nyckeln" Margin="0,2,8,0"/><ComboBox x:Name="ProfileResetCombo" Width="160"><ComboBoxItem Content="Ärv standard" IsSelected="True"/><ComboBoxItem Content="På"/><ComboBoxItem Content="Av"/></ComboBox></WrapPanel>
                                        </StackPanel>
                                    </Expander>
                                    <WrapPanel><Button x:Name="AddProfileButton" Content="Skapa profil" Style="{StaticResource PrimaryButton}"/><Button x:Name="EditProfileButton" Content="Spara ändringar"/></WrapPanel>
                                </StackPanel>
                            </GroupBox>
                            <GroupBox Header="Riskzon"><StackPanel><CheckBox x:Name="ForceProfileDeleteCheck" Content="Hoppa över CLI-bekräftelse (--force)"/><Button x:Name="DeleteProfileButton" Content="Radera profil" Style="{StaticResource DangerButton}" HorizontalAlignment="Left"/></StackPanel></GroupBox>
                        </StackPanel>
                    </ScrollViewer>
                </Grid>
            </TabItem>

            <TabItem Header="Providers">
                <Grid Margin="4,14,4,4">
                    <Grid.ColumnDefinitions><ColumnDefinition Width="38*"/><ColumnDefinition Width="12"/><ColumnDefinition Width="62*"/></Grid.ColumnDefinitions>
                    <GroupBox Grid.Column="0" Header="Provider-konfigurationer">
                        <Grid><Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/></Grid.RowDefinitions>
                            <Button x:Name="ListProvidersButton" Content="Uppdatera lista" Style="{StaticResource PrimaryButton}" HorizontalAlignment="Left"/>
                            <DataGrid x:Name="ProviderResultsGrid" Grid.Row="1" Margin="0,4,0,0"/>
                        </Grid>
                    </GroupBox>
                    <ScrollViewer Grid.Column="2" VerticalScrollBarVisibility="Auto">
                        <StackPanel>
                            <GroupBox Header="Providerinformation">
                                <StackPanel>
                                    <TextBlock Style="{StaticResource HintText}" Margin="0,0,0,8" Text="Markera en provider till vänster eller ange ett nytt konfigurationsnamn."/>
                                    <Label Content="Konfigurationsnamn"/><TextBox x:Name="ProviderNameText"/>
                                    <WrapPanel><Button x:Name="ShowProviderButton" Content="Visa detaljer"/><Button x:Name="ActivateProviderButton" Content="Aktivera"/></WrapPanel>
                                    <TextBox x:Name="ProviderDetailText" Height="100" IsReadOnly="True" AcceptsReturn="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Background="#F8FAFC"/>
                                </StackPanel>
                            </GroupBox>
                            <GroupBox Header="Lägg till eller redigera">
                                <StackPanel>
                                    <TextBlock Style="{StaticResource HintText}" Margin="0,0,0,8" Text="OAuth-inställningarna efterfrågas i en separat terminal."/>
                                    <Label Content="Providertyp"/><ComboBox x:Name="ProviderTypeCombo"><ComboBoxItem Content="ENTRA" IsSelected="True"/><ComboBoxItem Content="OKTA"/><ComboBoxItem Content="PING_ONE"/><ComboBoxItem Content="PING_ONE_AIC"/></ComboBox>
                                    <CheckBox x:Name="ActivateNewProviderCheck" Content="Aktivera när providern har lagts till"/>
                                    <WrapPanel><Button x:Name="AddProviderButton" Content="Ny provider  ↗" Style="{StaticResource PrimaryButton}" ToolTip="Öppnas i en interaktiv terminal"/><Button x:Name="EditProviderButton" Content="Redigera provider  ↗" ToolTip="Öppnas i en interaktiv terminal"/></WrapPanel>
                                </StackPanel>
                            </GroupBox>
                            <GroupBox Header="Riskzon"><StackPanel><CheckBox x:Name="ForceProviderDeleteCheck" Content="Hoppa över CLI-bekräftelse (--force)"/><Button x:Name="DeleteProviderButton" Content="Radera provider" Style="{StaticResource DangerButton}" HorizontalAlignment="Left"/></StackPanel></GroupBox>
                        </StackPanel>
                    </ScrollViewer>
                </Grid>
            </TabItem>

            <TabItem Header="Inställningar">
                <ScrollViewer VerticalScrollBarVisibility="Auto">
                    <StackPanel Margin="4,14,4,4">
                        <GroupBox Header="YubiEnroll">
                            <StackPanel>
                                <Label Content="Sökväg till yubienroll.exe"/>
                                <DockPanel><Button x:Name="BrowseExeButton" DockPanel.Dock="Right" Content="Bläddra..." Style="{StaticResource BrowseButton}"/><TextBox x:Name="ExePathText"/></DockPanel>
                                <Grid>
                                    <Grid.ColumnDefinitions><ColumnDefinition Width="240"/><ColumnDefinition/></Grid.ColumnDefinitions>
                                    <StackPanel Grid.Column="0" Margin="0,0,8,0">
                                        <Label Content="Loggnivå"/>
                                        <ComboBox x:Name="LogLevelCombo"><ComboBoxItem Content="Ingen" IsSelected="True"/><ComboBoxItem Content="ERROR"/><ComboBoxItem Content="WARNING"/><ComboBoxItem Content="INFO"/><ComboBoxItem Content="DEBUG"/><ComboBoxItem Content="TRAFFIC"/></ComboBox>
                                    </StackPanel>
                                    <StackPanel Grid.Column="1">
                                        <Label Content="Loggfil (kräver loggnivå)"/>
                                        <DockPanel><Button x:Name="BrowseLogButton" DockPanel.Dock="Right" Content="Bläddra..." Style="{StaticResource BrowseButton}"/><TextBox x:Name="LogFileText"/></DockPanel>
                                    </StackPanel>
                                </Grid>
                                <WrapPanel>
                                    <Button x:Name="CheckVersionButton" Content="Kontrollera version" Style="{StaticResource PrimaryButton}"/>
                                    <Button x:Name="OpenDocsButton" Content="Öppna dokumentation"/>
                                </WrapPanel>
                            </StackPanel>
                        </GroupBox>
                    </StackPanel>
                </ScrollViewer>
            </TabItem>
        </TabControl>

        <Expander x:Name="OutputExpander" Grid.Row="2" Margin="16,0,16,8" Header="Teknisk logg och CLI-utdata" IsExpanded="False">
            <Border Background="#101828" CornerRadius="5" Padding="12" Height="220" Margin="0,6,0,0">
                <Grid>
                    <Grid.RowDefinitions><RowDefinition Height="Auto"/><RowDefinition Height="*"/><RowDefinition Height="Auto"/></Grid.RowDefinitions>
                    <TextBlock x:Name="CommandPreviewText" Grid.Row="0" Text="Inget kommando har körts ännu." Foreground="#98A2B3" FontFamily="Consolas" FontSize="11" TextTrimming="CharacterEllipsis" Margin="0,0,0,7"/>
                    <TextBox x:Name="OutputText" Grid.Row="1" IsReadOnly="True" AcceptsReturn="True" TextWrapping="NoWrap"
                             VerticalScrollBarVisibility="Auto" HorizontalScrollBarVisibility="Auto"
                             Background="#101828" Foreground="#D0D5DD" BorderThickness="0" FontFamily="Consolas" FontSize="12"/>
                    <WrapPanel Grid.Row="2" HorizontalAlignment="Right" Margin="0,8,0,0">
                        <Button x:Name="StopButton" Content="Avbryt" IsEnabled="False" Style="{StaticResource CompactButton}"/>
                        <Button x:Name="CopyOutputButton" Content="Kopiera" Style="{StaticResource CompactButton}"/>
                        <Button x:Name="ClearOutputButton" Content="Rensa" Style="{StaticResource CompactButton}" Margin="0"/>
                    </WrapPanel>
                </Grid>
            </Border>
        </Expander>

        <Border Grid.Row="3" Background="#E4E7EC" Padding="16,6">
            <DockPanel>
                <StackPanel Orientation="Horizontal"><Ellipse x:Name="StatusDot" Width="8" Height="8" Fill="#12B76A" Margin="0,0,8,0"/><TextBlock x:Name="StatusText" Text="Redo" Foreground="#344054"/></StackPanel>
                <TextBlock DockPanel.Dock="Right" Text="PowerShell 7 • WPF" Foreground="#667085"/>
            </DockPanel>
        </Border>
    </Grid>
</Window>
'@

$xmlReader = [System.Xml.XmlNodeReader]::new([xml]$xaml)
$window = [System.Windows.Markup.XamlReader]::Load($xmlReader)

$controlNames = [regex]::Matches($xaml, 'x:Name="([^"]+)"') | ForEach-Object { $_.Groups[1].Value }
foreach ($controlName in $controlNames) {
    Set-Variable -Name $controlName -Value $window.FindName($controlName) -Scope Script
}

$ExePathText.Text = 'C:\Program Files\Yubico\YubiEnroll\yubienroll.exe'
$script:CurrentRun = $null
$script:DocumentationUrl = 'https://docs.yubico.com/software/yubikey/tools/yubienroll/commands.html'
$script:SettingsPath = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'YubiEnrollGUI\settings.json'

function Show-AppMessage {
    param(
        [Parameter(Mandatory)][string]$Message,
        [string]$Title = 'YubiEnroll',
        [System.Windows.MessageBoxImage]$Icon = [System.Windows.MessageBoxImage]::Information
    )
    [void][System.Windows.MessageBox]::Show($window, $Message, $Title, [System.Windows.MessageBoxButton]::OK, $Icon)
}

function Confirm-Action {
    param([Parameter(Mandatory)][string]$Message)
    return [System.Windows.MessageBoxResult]::Yes -eq [System.Windows.MessageBox]::Show(
        $window, $Message, 'Bekräfta åtgärd', [System.Windows.MessageBoxButton]::YesNo,
        [System.Windows.MessageBoxImage]::Warning
    )
}

function Add-Output {
    param([string]$Text)
    if ([string]::IsNullOrEmpty($Text)) { return }
    $OutputText.AppendText($Text)
    if (-not $Text.EndsWith([Environment]::NewLine)) {
        $OutputText.AppendText([Environment]::NewLine)
    }
    $OutputText.ScrollToEnd()
}

function Set-AppStatus {
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('Ready', 'Busy', 'Success', 'Warning', 'Error')][string]$State = 'Ready'
    )
    $colors = @{ Ready = '#667085'; Busy = '#F79009'; Success = '#12B76A'; Warning = '#F79009'; Error = '#F04438' }
    $StatusText.Text = $Message
    $StatusDot.Fill = [System.Windows.Media.BrushConverter]::new().ConvertFromString($colors[$State])
    if ($State -eq 'Error') { $OutputExpander.IsExpanded = $true }
}

function ConvertFrom-YubiTable {
    param([string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return @() }
    $clean = [regex]::Replace($Text, "`e\[[0-9;?]*[ -/]*[@-~]", '') -replace '[│┃║]', '|'
    $lines = @($clean -split '\r?\n' | ForEach-Object { $_.TrimEnd() })
    $separatorIndex = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '^\s*[|+\-─━═┄┅┈┉┼┬┴├┤┏┓┗┛╋╂┿╀╁┡┩┝┥ ]{3,}\s*$' -and $index -gt 0) { $separatorIndex = $index; break }
    }

    if ($separatorIndex -gt 0) {
        $headerLine = $lines[$separatorIndex - 1].Trim().Trim('|').Trim()
        $pipeTable = $headerLine.Contains('|')
        $headers = if ($pipeTable) { @($headerLine -split '\s*\|\s*') } else { @($headerLine -split '\s{2,}') }
        $headers = @($headers | ForEach-Object { if ([string]::IsNullOrWhiteSpace($_)) { 'Värde' } else { $_.Trim() } })
        $rows = [System.Collections.Generic.List[object]]::new()
        for ($index = $separatorIndex + 1; $index -lt $lines.Count; $index++) {
            $line = $lines[$index].Trim()
            if ([string]::IsNullOrWhiteSpace($line)) { continue }
            if ($line -match '^[|+\-─━═┄┅┈┉┼┬┴├┤┏┓┗┛╋╂┿╀╁┡┩┝┥ ]+$') { continue }
            if ($line -match '^(Use |ERROR:|Traceback)') { break }
            $values = if ($pipeTable -or $line.Contains('|')) { @($line.Trim('|').Trim() -split '\s*\|\s*') } else { @($line -split '\s{2,}') }
            if ($values.Count -eq 0) { continue }
            $properties = [ordered]@{}
            for ($column = 0; $column -lt $headers.Count; $column++) {
                $name = $headers[$column]
                if ($properties.Contains($name)) { $name = "$name $($column + 1)" }
                $properties[$name] = if ($column -lt $values.Count) { $values[$column].Trim() } else { '' }
            }
            $rows.Add([pscustomobject]$properties)
        }
        # A valid table with no data rows is still an empty result. Falling
        # through here would incorrectly turn the column header into an item.
        return $rows.ToArray()
    }

    # Some YubiEnroll builds emit aligned columns without a dashed separator.
    # Recognize the heading and split subsequent rows on column-sized spacing.
    $headerIndex = -1
    for ($index = 0; $index -lt $lines.Count; $index++) {
        if ($lines[$index] -match '\s{2,}' -and $lines[$index] -match '(?i)(^Name\s|^ID\s|Username|Credential|Provider)') {
            $headerIndex = $index
            break
        }
    }
    if ($headerIndex -ge 0) {
        $headers = @($lines[$headerIndex].Trim() -split '\s{2,}')
        $rows = [System.Collections.Generic.List[object]]::new()
        for ($index = $headerIndex + 1; $index -lt $lines.Count; $index++) {
            $line = $lines[$index].Trim()
            if ([string]::IsNullOrWhiteSpace($line) -or $line -match '^(No .+ found|Use |ERROR:)') { continue }
            if ($line -match '^[|+\-─━═ ]+$') { continue }
            $values = @($line -split '\s{2,}')
            if ($values.Count -lt 2) { continue }
            $properties = [ordered]@{}
            for ($column = 0; $column -lt $headers.Count; $column++) {
                $properties[$headers[$column].Trim()] = if ($column -lt $values.Count) { $values[$column].Trim() } else { '' }
            }
            $rows.Add([pscustomobject]$properties)
        }
        return $rows.ToArray()
    }

    $fallback = @($lines | ForEach-Object { $_.Trim().Trim('|').Trim() } | Where-Object {
        $_ -and $_ -notmatch '^(No .+ found\.?|Use |ERROR:|Traceback|File |\^)' -and
        $_ -notmatch '^(?i)Name\s{2,}.+(PIN|Provider|Active|Username|Credential)' -and
        $_ -notmatch '^[|+\-─━═┄┅┈┉┼┬┴├┤┏┓┗┛╋╂┿╀╁┡┩┝┥ ]+$'
    })
    return @($fallback | ForEach-Object { [pscustomobject]@{ Värde = $_ } })
}

function Set-GridFromOutput {
    param([System.Windows.Controls.DataGrid]$Grid, [string]$Text)
    $Grid.ItemsSource = $null
    $items = @(ConvertFrom-YubiTable $Text)
    if ($items.Count -gt 0) { $Grid.ItemsSource = $items }
    return $items.Count
}

function Get-RowValue {
    param([object]$Row, [string[]]$PreferredNames)
    if ($null -eq $Row) { return '' }
    $properties = @($Row.PSObject.Properties)
    foreach ($pattern in $PreferredNames) {
        $match = $properties | Where-Object { $_.Name -match $pattern } | Select-Object -First 1
        if ($null -ne $match -and -not [string]::IsNullOrWhiteSpace([string]$match.Value)) { return [string]$match.Value }
    }
    $first = $properties | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_.Value) } | Select-Object -First 1
    return if ($null -ne $first) { [string]$first.Value } else { '' }
}

function Find-RowValue {
    param([object]$Row, [string[]]$PreferredNames)
    if ($null -eq $Row) { return '' }
    foreach ($pattern in $PreferredNames) {
        $match = $Row.PSObject.Properties | Where-Object { $_.Name -match $pattern } | Select-Object -First 1
        if ($null -ne $match) { return [string]$match.Value }
    }
    return ''
}

function Set-BooleanComboFromValue {
    param([System.Windows.Controls.ComboBox]$ComboBox, [string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) { Set-ComboByText $ComboBox 'Ärv standard'; return }
    if ($Value -match '(?i)^(true|yes|on|enabled|ja|på|1)$') { Set-ComboByText $ComboBox 'På' }
    elseif ($Value -match '(?i)^(false|no|off|disabled|nej|av|0)$') { Set-ComboByText $ComboBox 'Av' }
    else { Set-ComboByText $ComboBox 'Ärv standard' }
}

function Update-EnrollmentSummary {
    $user = if ([string]::IsNullOrWhiteSpace($CredentialUserText.Text)) { 'ingen användare vald' } else { $CredentialUserText.Text.Trim() }
    $policy = if ([string]::IsNullOrWhiteSpace($EnrollProfileText.Text)) { 'providerns standard eller egna avancerade val' } else { "profilen '$($EnrollProfileText.Text.Trim())'" }
    $EnrollmentSummaryText.Text = "Registrera för $user med $policy."
    $SelectedUserValue.Text = if ([string]::IsNullOrWhiteSpace($CredentialUserText.Text)) { 'Ingen vald' } else { $CredentialUserText.Text.Trim() }
}

function Set-ComboByText {
    param([System.Windows.Controls.ComboBox]$ComboBox, [string]$Text)
    foreach ($item in $ComboBox.Items) {
        if ([string]$item.Content -eq $Text) { $ComboBox.SelectedItem = $item; return }
    }
}

function Save-AppSettings {
    if ($SelfTest) { return }
    try {
        $directory = Split-Path -Parent $script:SettingsPath
        if (-not [System.IO.Directory]::Exists($directory)) { [void][System.IO.Directory]::CreateDirectory($directory) }
        $settings = [ordered]@{
            ExePath = $ExePathText.Text
            LogLevel = Get-ComboText $LogLevelCombo
            LogFile = $LogFileText.Text
            ProviderName = $ProviderNameText.Text
            WindowWidth = $window.ActualWidth
            WindowHeight = $window.ActualHeight
            AdvancedEnrollmentExpanded = [bool]$EnrollAdvancedExpander.IsExpanded
            AdvancedProfileExpanded = [bool]$ProfileAdvancedExpander.IsExpanded
            OutputExpanded = [bool]$OutputExpander.IsExpanded
            NoLaunchBrowser = [bool]$NoLaunchBrowserCheck.IsChecked
        }
        $settings | ConvertTo-Json | Set-Content -LiteralPath $script:SettingsPath -Encoding utf8
    }
    catch { Add-Output "Inställningarna kunde inte sparas: $($_.Exception.Message)" }
}

function Load-AppSettings {
    if (-not [System.IO.File]::Exists($script:SettingsPath)) { return }
    try {
        $settings = Get-Content -Raw -LiteralPath $script:SettingsPath | ConvertFrom-Json
        if ($settings.ExePath) { $ExePathText.Text = [string]$settings.ExePath }
        if ($null -ne $settings.LogLevel) { Set-ComboByText $LogLevelCombo ([string]$settings.LogLevel) }
        if ($null -ne $settings.LogFile) { $LogFileText.Text = [string]$settings.LogFile }
        if ($null -ne $settings.ProviderName) { $ProviderNameText.Text = [string]$settings.ProviderName }
        if ($settings.WindowWidth -ge $window.MinWidth) { $window.Width = [double]$settings.WindowWidth }
        if ($settings.WindowHeight -ge $window.MinHeight) { $window.Height = [double]$settings.WindowHeight }
        if ($null -ne $settings.AdvancedEnrollmentExpanded) { $EnrollAdvancedExpander.IsExpanded = [bool]$settings.AdvancedEnrollmentExpanded }
        if ($null -ne $settings.AdvancedProfileExpanded) { $ProfileAdvancedExpander.IsExpanded = [bool]$settings.AdvancedProfileExpanded }
        if ($null -ne $settings.OutputExpanded) { $OutputExpander.IsExpanded = [bool]$settings.OutputExpanded }
        if ($null -ne $settings.NoLaunchBrowser) { $NoLaunchBrowserCheck.IsChecked = [bool]$settings.NoLaunchBrowser }
    }
    catch { Add-Output "Sparade inställningar kunde inte läsas: $($_.Exception.Message)" }
}

function Get-ComboText {
    param([System.Windows.Controls.ComboBox]$ComboBox)
    if ($null -eq $ComboBox.SelectedItem) { return '' }
    return [string]$ComboBox.SelectedItem.Content
}

function Get-GlobalArguments {
    $arguments = [System.Collections.Generic.List[string]]::new()
    $level = Get-ComboText $LogLevelCombo
    if ($level -ne 'Ingen') {
        $arguments.Add('--log-level')
        $arguments.Add($level.ToLowerInvariant())
        if (-not [string]::IsNullOrWhiteSpace($LogFileText.Text)) {
            $arguments.Add('--log-file')
            $arguments.Add($LogFileText.Text.Trim())
        }
    }
    elseif (-not [string]::IsNullOrWhiteSpace($LogFileText.Text)) {
        throw 'Välj en loggnivå om en loggfil ska användas.'
    }
    return $arguments.ToArray()
}

function Assert-Executable {
    if ([string]::IsNullOrWhiteSpace($ExePathText.Text) -or -not [System.IO.File]::Exists($ExePathText.Text.Trim())) {
        throw 'YubiEnroll-filen hittades inte. Kontrollera sökvägen under Inställningar.'
    }
}

function Assert-RequiredText {
    param([System.Windows.Controls.TextBox]$TextBox, [string]$FieldName)
    if ([string]::IsNullOrWhiteSpace($TextBox.Text)) { throw "Fältet '$FieldName' måste fyllas i." }
    return $TextBox.Text.Trim()
}

function Add-RangedIntegerArgument {
    param(
        [System.Collections.Generic.List[string]]$Arguments,
        [System.Windows.Controls.TextBox]$TextBox,
        [string]$Option,
        [string]$FieldName
    )
    if ([string]::IsNullOrWhiteSpace($TextBox.Text)) { return }
    $number = 0
    if (-not [int]::TryParse($TextBox.Text.Trim(), [ref]$number) -or $number -lt 4 -or $number -gt 63) {
        throw "$FieldName måste vara ett heltal mellan 4 och 63."
    }
    $Arguments.Add($Option)
    $Arguments.Add([string]$number)
}

function Add-TriStateArgument {
    param(
        [System.Collections.Generic.List[string]]$Arguments,
        [System.Windows.Controls.ComboBox]$ComboBox,
        [string]$PositiveOption,
        [string]$NegativeOption
    )
    switch (Get-ComboText $ComboBox) {
        'På' { $Arguments.Add($PositiveOption) }
        'Av' { $Arguments.Add($NegativeOption) }
    }
}

function Get-AuthenticatorArguments {
    param([ValidateSet('Enroll', 'Profile')][string]$Prefix)
    $arguments = [System.Collections.Generic.List[string]]::new()
    if ($Prefix -eq 'Enroll') {
        Add-RangedIntegerArgument $arguments $EnrollMinPinText '--min-pin-length' 'Minsta PIN-längd'
        Add-RangedIntegerArgument $arguments $EnrollRandomPinLengthText '--random-pin-length' 'Slumpmässig PIN-längd'
        Add-TriStateArgument $arguments $EnrollAlwaysUvCombo '--require-always-uv' '--no-require-always-uv'
        Add-TriStateArgument $arguments $EnrollEaCombo '--require-ea' '--no-require-ea'
        Add-TriStateArgument $arguments $EnrollForcePinCombo '--force-pin-change' '--no-force-pin-change'
        Add-TriStateArgument $arguments $EnrollResetCombo '--reset' '--no-reset'
        Add-TriStateArgument $arguments $EnrollRandomPinCombo '--random-pin' '--no-random-pin'
    }
    else {
        Add-RangedIntegerArgument $arguments $ProfileMinPinText '--min-pin-length' 'Minsta PIN-längd'
        Add-RangedIntegerArgument $arguments $ProfileRandomPinLengthText '--random-pin-length' 'Slumpmässig PIN-längd'
        Add-TriStateArgument $arguments $ProfileAlwaysUvCombo '--require-always-uv' '--no-require-always-uv'
        Add-TriStateArgument $arguments $ProfileEaCombo '--require-ea' '--no-require-ea'
        Add-TriStateArgument $arguments $ProfileForcePinCombo '--force-pin-change' '--no-force-pin-change'
        Add-TriStateArgument $arguments $ProfileResetCombo '--reset' '--no-reset'
        Add-TriStateArgument $arguments $ProfileRandomPinCombo '--random-pin' '--no-random-pin'
    }
    return $arguments.ToArray()
}

function Format-CommandArgument {
    param([string]$Value)
    if ($Value -notmatch '[\s"]') { return $Value }
    return '"' + $Value.Replace('"', '\"') + '"'
}

function Format-CommandLine {
    param([string[]]$Arguments)
    $parts = @((Format-CommandArgument $ExePathText.Text.Trim())) + @($Arguments | ForEach-Object { Format-CommandArgument $_ })
    return $parts -join ' '
}

function Start-CapturedCommand {
    param(
        [Parameter(Mandatory)][string[]]$Arguments,
        [string]$Description = 'Kör kommando',
        [scriptblock]$OnCompleted
    )
    try {
        Assert-Executable
        if ($null -ne $script:CurrentRun -and -not $script:CurrentRun.WaitTask.IsCompleted) {
            throw 'Ett kommando körs redan. Vänta tills det är klart eller klicka på Avbryt.'
        }
        $allArguments = @((Get-GlobalArguments)) + $Arguments
        $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = $ExePathText.Text.Trim()
        $startInfo.UseShellExecute = $false
        $startInfo.RedirectStandardOutput = $true
        $startInfo.RedirectStandardError = $true
        $startInfo.CreateNoWindow = $true
        foreach ($argument in $allArguments) { [void]$startInfo.ArgumentList.Add($argument) }

        $process = [System.Diagnostics.Process]::new()
        $process.StartInfo = $startInfo
        if (-not $process.Start()) { throw 'Processen kunde inte startas.' }
        $stdoutTask = $process.StandardOutput.ReadToEndAsync()
        $stderrTask = $process.StandardError.ReadToEndAsync()
        $waitTask = $process.WaitForExitAsync()
        $script:CurrentRun = [pscustomobject]@{
            Process = $process; StdoutTask = $stdoutTask; StderrTask = $stderrTask
            WaitTask = $waitTask; Description = $Description; CommandLine = (Format-CommandLine $allArguments)
            OnCompleted = $OnCompleted
        }
        $CommandPreviewText.Text = $script:CurrentRun.CommandLine
        Add-Output "`r`n[$(Get-Date -Format 'HH:mm:ss')] $Description"
        Add-Output "> $($script:CurrentRun.CommandLine)"
        Set-AppStatus "$Description..." Busy
        $StopButton.IsEnabled = $true
    }
    catch {
        Set-AppStatus 'Kommandot kunde inte startas' Error
        Show-AppMessage $_.Exception.Message 'Kan inte köra kommandot' ([System.Windows.MessageBoxImage]::Error)
    }
}

function ConvertTo-SingleQuotedLiteral {
    param([string]$Value)
    return "'" + $Value.Replace("'", "''") + "'"
}

function Start-InteractiveCommand {
    param([Parameter(Mandatory)][string[]]$Arguments, [string]$Description = 'Interaktivt kommando')
    try {
        Assert-Executable
        $allArguments = @((Get-GlobalArguments)) + $Arguments
        $exeLiteral = ConvertTo-SingleQuotedLiteral $ExePathText.Text.Trim()
        $argumentLiterals = @($allArguments | ForEach-Object { ConvertTo-SingleQuotedLiteral $_ }) -join ', '
        $commandLine = Format-CommandLine $allArguments
        $interactiveScript = @"
`$Host.UI.RawUI.WindowTitle = 'YubiEnroll – $($Description.Replace("'", "''"))'
Write-Host 'YubiEnroll GUI startade följande kommando:' -ForegroundColor Cyan
Write-Host '$($commandLine.Replace("'", "''"))' -ForegroundColor DarkGray
Write-Host ''
`$arguments = @($argumentLiterals)
& $exeLiteral @arguments
`$exitCode = `$LASTEXITCODE
Write-Host ''
if (`$exitCode -eq 0) { Write-Host 'Kommandot slutfördes.' -ForegroundColor Green }
else { Write-Host "Kommandot avslutades med kod `$exitCode." -ForegroundColor Red }
"@
        $encoded = [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes($interactiveScript))
        $pwsh = (Get-Command pwsh.exe -ErrorAction Stop).Source
        $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
        $startInfo.FileName = $pwsh
        $startInfo.UseShellExecute = $true
        foreach ($argument in @('-NoLogo', '-NoProfile', '-NoExit', '-EncodedCommand', $encoded)) {
            [void]$startInfo.ArgumentList.Add($argument)
        }
        [void][System.Diagnostics.Process]::Start($startInfo)
        $CommandPreviewText.Text = $commandLine
        Add-Output "`r`n[$(Get-Date -Format 'HH:mm:ss')] Startade interaktiv konsol: $Description"
        Add-Output "> $commandLine"
        Set-AppStatus 'Interaktiv terminal startad' Success
    }
    catch {
        Set-AppStatus 'Terminalen kunde inte öppnas' Error
        Show-AppMessage $_.Exception.Message 'Kan inte öppna konsolen' ([System.Windows.MessageBoxImage]::Error)
    }
}

function Invoke-ProfileCommand {
    param([ValidateSet('add', 'edit')][string]$Action)
    try {
        $name = Assert-RequiredText $ProfileNameText 'Profilnamn'
        $arguments = [System.Collections.Generic.List[string]]::new()
        $arguments.Add('profiles'); $arguments.Add($Action); $arguments.Add($name)
        foreach ($option in (Get-AuthenticatorArguments -Prefix Profile)) { $arguments.Add($option) }
        Start-CapturedCommand $arguments.ToArray() $(if ($Action -eq 'add') { 'Lägger till profil' } else { 'Uppdaterar profil' }) {
            Set-AppStatus 'Profilen sparades' Success
            Start-CapturedCommand @('profiles', 'list') 'Uppdaterar profillistan' {
                param($stdout)
                [void](Set-GridFromOutput $ProfilesGrid $stdout)
            }
        }
    }
    catch { Show-AppMessage $_.Exception.Message 'Kontrollera inmatningen' ([System.Windows.MessageBoxImage]::Warning) }
}

Load-AppSettings
Update-EnrollmentSummary

$pollTimer = [System.Windows.Threading.DispatcherTimer]::new()
$pollTimer.Interval = [TimeSpan]::FromMilliseconds(200)
$pollTimer.Add_Tick({
    if ($null -eq $script:CurrentRun -or -not $script:CurrentRun.WaitTask.IsCompleted) { return }
    $run = $script:CurrentRun
    $script:CurrentRun = $null
    try {
        $stdout = $run.StdoutTask.GetAwaiter().GetResult()
        $stderr = $run.StderrTask.GetAwaiter().GetResult()
        if (-not [string]::IsNullOrWhiteSpace($stdout)) { Add-Output $stdout.TrimEnd() }
        if (-not [string]::IsNullOrWhiteSpace($stderr)) { Add-Output $stderr.TrimEnd() }
        if ($stderr -match '0x8010001D|Resurshanteraren för smartkort körs inte') {
            Add-Output 'Tips: Windows-tjänsten Smartkort (SCardSvr) måste vara igång för att NFC-läsare ska kunna listas.'
        }
        $exitCode = $run.Process.ExitCode
        Add-Output "[$(Get-Date -Format 'HH:mm:ss')] Klart (avslutningskod $exitCode)."
        if ($exitCode -eq 0) {
            Set-AppStatus 'Klart' Success
            if ($null -ne $run.OnCompleted) { & $run.OnCompleted $stdout $stderr $exitCode }
        }
        else {
            if ($run.Description -match 'kortläsare') { $ReaderStatusValue.Text = 'Fel – se logg' }
            if ($run.Description -match 'status') { $LoginStatusValue.Text = 'Kunde inte hämtas' }
            Set-AppStatus "Kommandot misslyckades (kod $exitCode)" Error
        }
    }
    catch {
        Add-Output "Fel när resultatet lästes: $($_.Exception.Message)"
        Set-AppStatus 'Ett fel inträffade' Error
    }
    finally {
        $run.Process.Dispose()
        $StopButton.IsEnabled = ($null -ne $script:CurrentRun)
    }
})
$pollTimer.Start()

$StatusButton.Add_Click({
    Start-CapturedCommand @('status') 'Hämtar status' {
        param($stdout)
        if ($stdout -match '(?i)No providers found') {
            $ActiveProviderValue.Text = 'Ingen konfigurerad'
            $LoginStatusValue.Text = 'Inte tillgänglig'
            return
        }
        $activeMatch = [regex]::Match($stdout, '(?im)^(?:active provider(?: configuration)?|provider)\s*:\s*(.+)$')
        $loginMatch = [regex]::Match($stdout, '(?im)^(?:authenticated|authentication status|logged in)\s*:\s*(.+)$')
        $ActiveProviderValue.Text = if ($activeMatch.Success) { $activeMatch.Groups[1].Value.Trim() } else { 'Se teknisk logg' }
        $LoginStatusValue.Text = if ($loginMatch.Success) { $loginMatch.Groups[1].Value.Trim() } else { 'Status hämtad' }
    }
})
$ReadersButton.Add_Click({
    Start-CapturedCommand @('readers') 'Kontrollerar kortläsare' {
        param($stdout)
        $items = @(ConvertFrom-YubiTable $stdout)
        $ReaderStatusValue.Text = if ($items.Count -eq 0) { 'Ingen hittad' } elseif ($items.Count -eq 1) { '1 tillgänglig' } else { "$($items.Count) tillgängliga" }
    }
})
$LoginButton.Add_Click({
    $arguments = @('login')
    if ($NoLaunchBrowserCheck.IsChecked) { $arguments += '--no-launch-browser' }
    Start-InteractiveCommand $arguments 'Loggar in'
})
$LogoutButton.Add_Click({ Start-CapturedCommand @('logout') 'Loggar ut' { $LoginStatusValue.Text = 'Utloggad' } })
$SearchUsersButton.Add_Click({
    $arguments = [System.Collections.Generic.List[string]]::new(); $arguments.Add('users')
    if (-not [string]::IsNullOrWhiteSpace($UserQueryText.Text)) { $arguments.Add($UserQueryText.Text.Trim()) }
    Start-CapturedCommand $arguments.ToArray() 'Söker användare' {
        param($stdout)
        $count = Set-GridFromOutput $UserResultsGrid $stdout
        Set-AppStatus "$count användare i resultatet" Success
    }
})
$UserQueryText.Add_KeyDown({ if ($_.Key -eq [System.Windows.Input.Key]::Enter) { $SearchUsersButton.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent)) } })
$ListCredentialsButton.Add_Click({
    try {
        $user = Assert-RequiredText $CredentialUserText 'Användar-ID eller användarnamn'
        Start-CapturedCommand @('credentials', 'list', $user) 'Listar credentials' {
            param($stdout)
            $count = Set-GridFromOutput $CredentialResultsGrid $stdout
            Set-AppStatus "$count credentials i resultatet" Success
        }
    }
    catch { Show-AppMessage $_.Exception.Message 'Kontrollera inmatningen' ([System.Windows.MessageBoxImage]::Warning) }
})
$DeleteCredentialsButton.Add_Click({
    try {
        $user = Assert-RequiredText $CredentialUserText 'Användar-ID eller användarnamn'
        $credentialDescription = if ([string]::IsNullOrWhiteSpace($CredentialIdsText.Text)) { 'credentials som väljs i YubiEnroll' } else { "credential-ID $($CredentialIdsText.Text.Trim())" }
        if (-not (Confirm-Action "Vill du radera $credentialDescription för användaren '$user'? Åtgärden kan inte ångras.")) { return }
        $arguments = [System.Collections.Generic.List[string]]::new(); $arguments.Add('credentials'); $arguments.Add('delete'); $arguments.Add($user)
        foreach ($id in ($CredentialIdsText.Text -split '\s+' | Where-Object { $_ })) { $arguments.Add($id) }
        if ($ForceCredentialDeleteCheck.IsChecked) { $arguments.Add('--force') }
        if ($ForceCredentialDeleteCheck.IsChecked -and -not [string]::IsNullOrWhiteSpace($CredentialIdsText.Text)) {
            Start-CapturedCommand $arguments.ToArray() 'Raderar credentials'
        } else { Start-InteractiveCommand $arguments.ToArray() 'Raderar credentials' }
    }
    catch { Show-AppMessage $_.Exception.Message 'Kontrollera inmatningen' ([System.Windows.MessageBoxImage]::Warning) }
})
$EnrollButton.Add_Click({
    try {
        $user = Assert-RequiredText $CredentialUserText 'Användar-ID eller användarnamn'
        $arguments = [System.Collections.Generic.List[string]]::new(); $arguments.Add('credentials'); $arguments.Add('add'); $arguments.Add($user)
        if (-not [string]::IsNullOrWhiteSpace($EnrollReaderText.Text)) { $arguments.Add('--reader'); $arguments.Add($EnrollReaderText.Text.Trim()) }
        if (-not [string]::IsNullOrWhiteSpace($EnrollProfileText.Text)) { $arguments.Add('--profile'); $arguments.Add($EnrollProfileText.Text.Trim()) }
        if (-not [string]::IsNullOrWhiteSpace($EnrollDisplayNameText.Text)) { $arguments.Add('--display-name'); $arguments.Add($EnrollDisplayNameText.Text.Trim()) }
        foreach ($option in (Get-AuthenticatorArguments -Prefix Enroll)) { $arguments.Add($option) }
        if ($EnrollForceCheck.IsChecked) { $arguments.Add('--force') }
        Start-InteractiveCommand $arguments.ToArray() 'Registrerar credential'
    }
    catch { Show-AppMessage $_.Exception.Message 'Kontrollera inmatningen' ([System.Windows.MessageBoxImage]::Warning) }
})
$ListProfilesButton.Add_Click({
    Start-CapturedCommand @('profiles', 'list') 'Listar profiler' {
        param($stdout)
        $count = Set-GridFromOutput $ProfilesGrid $stdout
        Set-AppStatus "$count profiler i listan" Success
    }
})
$AddProfileButton.Add_Click({ Invoke-ProfileCommand add })
$EditProfileButton.Add_Click({ Invoke-ProfileCommand edit })
$DeleteProfileButton.Add_Click({
    try {
        $name = Assert-RequiredText $ProfileNameText 'Profilnamn'
        if (-not (Confirm-Action "Vill du radera profilen '$name'?")) { return }
        $arguments = @('profiles', 'delete', $name) + $(if ($ForceProfileDeleteCheck.IsChecked) { @('--force') } else { @() })
        if ($ForceProfileDeleteCheck.IsChecked) {
            Start-CapturedCommand $arguments 'Raderar profil' {
                $ProfileNameText.Clear()
                Start-CapturedCommand @('profiles', 'list') 'Uppdaterar profillistan' { param($stdout); [void](Set-GridFromOutput $ProfilesGrid $stdout) }
            }
        }
        else { Start-InteractiveCommand $arguments 'Raderar profil' }
    }
    catch { Show-AppMessage $_.Exception.Message 'Kontrollera inmatningen' ([System.Windows.MessageBoxImage]::Warning) }
})
$ListProvidersButton.Add_Click({
    Start-CapturedCommand @('providers', 'list') 'Listar providers' {
        param($stdout)
        $count = Set-GridFromOutput $ProviderResultsGrid $stdout
        Set-AppStatus "$count providers i listan" Success
    }
})
$ShowProviderButton.Add_Click({
    try {
        $name = Assert-RequiredText $ProviderNameText 'Konfigurationsnamn'
        Start-CapturedCommand @('providers', 'show', $name) 'Visar provider' { param($stdout); $ProviderDetailText.Text = $stdout.Trim() }
    }
    catch { Show-AppMessage $_.Exception.Message 'Kontrollera inmatningen' ([System.Windows.MessageBoxImage]::Warning) }
})
$ActivateProviderButton.Add_Click({
    try {
        $name = Assert-RequiredText $ProviderNameText 'Konfigurationsnamn'
        $onActivated = { $ActiveProviderValue.Text = $name; Set-AppStatus "Providern '$name' är aktiv" Success }.GetNewClosure()
        Start-CapturedCommand @('providers', 'activate', $name) 'Aktiverar provider' $onActivated
    }
    catch { Show-AppMessage $_.Exception.Message 'Kontrollera inmatningen' ([System.Windows.MessageBoxImage]::Warning) }
})
$AddProviderButton.Add_Click({
    try {
        $name = Assert-RequiredText $ProviderNameText 'Konfigurationsnamn'
        $arguments = [System.Collections.Generic.List[string]]::new(); $arguments.Add('providers'); $arguments.Add('add'); $arguments.Add($name)
        $arguments.Add('--provider'); $arguments.Add((Get-ComboText $ProviderTypeCombo))
        if ($ActivateNewProviderCheck.IsChecked) { $arguments.Add('--activate') }
        Start-InteractiveCommand $arguments.ToArray() 'Lägger till provider'
    }
    catch { Show-AppMessage $_.Exception.Message 'Kontrollera inmatningen' ([System.Windows.MessageBoxImage]::Warning) }
})
$EditProviderButton.Add_Click({
    try { $name = Assert-RequiredText $ProviderNameText 'Konfigurationsnamn'; Start-InteractiveCommand @('providers', 'edit', $name) 'Redigerar provider' }
    catch { Show-AppMessage $_.Exception.Message 'Kontrollera inmatningen' ([System.Windows.MessageBoxImage]::Warning) }
})
$DeleteProviderButton.Add_Click({
    try {
        $name = Assert-RequiredText $ProviderNameText 'Konfigurationsnamn'
        if (-not (Confirm-Action "Vill du radera provider-konfigurationen '$name'?")) { return }
        $arguments = @('providers', 'delete', $name) + $(if ($ForceProviderDeleteCheck.IsChecked) { @('--force') } else { @() })
        if ($ForceProviderDeleteCheck.IsChecked) {
            Start-CapturedCommand $arguments 'Raderar provider' {
                $ProviderNameText.Clear(); $ProviderDetailText.Clear()
                Start-CapturedCommand @('providers', 'list') 'Uppdaterar providerlistan' { param($stdout); [void](Set-GridFromOutput $ProviderResultsGrid $stdout) }
            }
        }
        else { Start-InteractiveCommand $arguments 'Raderar provider' }
    }
    catch { Show-AppMessage $_.Exception.Message 'Kontrollera inmatningen' ([System.Windows.MessageBoxImage]::Warning) }
})

$UserResultsGrid.Add_SelectionChanged({
    $row = $UserResultsGrid.SelectedItem
    $user = Get-RowValue $row @('(?i)^ID$', '(?i)User.?ID', '(?i)Username', '(?i)User', '(?i)Värde')
    if (-not [string]::IsNullOrWhiteSpace($user)) {
        $CredentialUserText.Text = $user
        Update-EnrollmentSummary
        $label = Find-RowValue $row @('(?i)Display.?Name', '(?i)Username')
        if (-not [string]::IsNullOrWhiteSpace($label)) { $SelectedUserValue.Text = $label }
    }
})
$CredentialResultsGrid.Add_SelectionChanged({
    $ids = [System.Collections.Generic.List[string]]::new()
    foreach ($row in $CredentialResultsGrid.SelectedItems) {
        $id = Get-RowValue $row @('(?i)Credential.?ID', '(?i)^ID$', '(?i)Värde')
        if (-not [string]::IsNullOrWhiteSpace($id)) { $ids.Add($id) }
    }
    if ($ids.Count -gt 0) { $CredentialIdsText.Text = $ids -join ' ' }
})
$ProfilesGrid.Add_SelectionChanged({
    $row = $ProfilesGrid.SelectedItem
    $name = Get-RowValue $row @('(?i)^Name$', '(?i)Profile', '(?i)Namn', '(?i)Värde')
    if ($name -match '\s{2,}') { $name = ($name -split '\s{2,}', 2)[0] }
    if (-not [string]::IsNullOrWhiteSpace($name)) {
        $ProfileNameText.Text = $name
        $EnrollProfileText.Text = $name
        $ProfileMinPinText.Text = Find-RowValue $row @('(?i)Min.*PIN')
        $ProfileRandomPinLengthText.Text = Find-RowValue $row @('(?i)Random.*PIN.*Length', '(?i)Slump.*PIN.*längd')
        Set-BooleanComboFromValue $ProfileAlwaysUvCombo (Find-RowValue $row @('(?i)Always.*UV'))
        Set-BooleanComboFromValue $ProfileEaCombo (Find-RowValue $row @('(?i)Enterprise.*Attestation', '(?i)Require.*EA'))
        Set-BooleanComboFromValue $ProfileForcePinCombo (Find-RowValue $row @('(?i)Force.*PIN'))
        Set-BooleanComboFromValue $ProfileResetCombo (Find-RowValue $row @('(?i)^Reset'))
        Set-BooleanComboFromValue $ProfileRandomPinCombo (Find-RowValue $row @('(?i)^Random.*PIN$', '(?i)^Slump.*PIN$'))
    }
})
$ProviderResultsGrid.Add_SelectionChanged({
    $row = $ProviderResultsGrid.SelectedItem
    $name = Get-RowValue $row @('(?i)^Name$', '(?i)Configuration', '(?i)Namn', '(?i)Värde')
    if (-not [string]::IsNullOrWhiteSpace($name)) {
        $ProviderNameText.Text = $name
        $type = Find-RowValue $row @('(?i)Provider.?Type', '(?i)Identity.?Provider', '(?i)^Type$')
        if (-not [string]::IsNullOrWhiteSpace($type)) { Set-ComboByText $ProviderTypeCombo $type.Trim().ToUpperInvariant() }
        $active = Find-RowValue $row @('(?i)^Active$', '(?i)Aktiv')
        if ($active -match '(?i)^(true|yes|ja|active|aktiv|\*)$') { $ActiveProviderValue.Text = $name }
    }
})
$CredentialUserText.Add_TextChanged({ Update-EnrollmentSummary })
$EnrollProfileText.Add_TextChanged({ Update-EnrollmentSummary })
$EnrollRandomPinCombo.Add_SelectionChanged({ $EnrollRandomPinLengthText.IsEnabled = (Get-ComboText $EnrollRandomPinCombo) -eq 'På' })
$ProfileRandomPinCombo.Add_SelectionChanged({ $ProfileRandomPinLengthText.IsEnabled = (Get-ComboText $ProfileRandomPinCombo) -eq 'På' })

$BrowseExeButton.Add_Click({
    $dialog = [Microsoft.Win32.OpenFileDialog]::new(); $dialog.Filter = 'Program (*.exe)|*.exe|Alla filer (*.*)|*.*'; $dialog.FileName = 'yubienroll.exe'
    if ($dialog.ShowDialog($window)) { $ExePathText.Text = $dialog.FileName }
})
$BrowseLogButton.Add_Click({
    $dialog = [Microsoft.Win32.SaveFileDialog]::new(); $dialog.Filter = 'Loggfiler (*.log)|*.log|Textfiler (*.txt)|*.txt|Alla filer (*.*)|*.*'; $dialog.FileName = 'yubienroll.log'
    if ($dialog.ShowDialog($window)) { $LogFileText.Text = $dialog.FileName }
})
$CheckVersionButton.Add_Click({ Start-CapturedCommand @('--version') 'Kontrollerar version' { param($stdout); $VersionText.Text = $stdout.Trim() } })
$OpenDocsButton.Add_Click({ Start-Process $script:DocumentationUrl })
$ClearOutputButton.Add_Click({ $OutputText.Clear(); $CommandPreviewText.Text = 'Inget kommando har körts ännu.' })
$CopyOutputButton.Add_Click({ if (-not [string]::IsNullOrEmpty($OutputText.Text)) { [System.Windows.Clipboard]::SetText($OutputText.Text); Set-AppStatus 'Utdata kopierad' Success } })
$StopButton.Add_Click({
    if ($null -ne $script:CurrentRun -and -not $script:CurrentRun.Process.HasExited) {
        try { $script:CurrentRun.Process.Kill($true); Add-Output 'Processen avbröts av användaren.'; Set-AppStatus 'Avbruten' Warning }
        catch { Add-Output "Kunde inte avbryta processen: $($_.Exception.Message)" }
    }
})
$window.Add_Closing({
    Save-AppSettings
    $pollTimer.Stop()
    if ($null -ne $script:CurrentRun -and -not $script:CurrentRun.Process.HasExited) {
        try { $script:CurrentRun.Process.Kill($true) } catch { }
    }
})
$window.Add_ContentRendered({
    if ([System.IO.File]::Exists($ExePathText.Text)) {
        try {
            $versionInfo = & $ExePathText.Text --version 2>&1 | Out-String
            $VersionText.Text = $versionInfo.Trim()
            Add-Output "[$(Get-Date -Format 'HH:mm:ss')] $($versionInfo.Trim()) hittades."
        }
        catch { $VersionText.Text = 'Version kunde inte läsas' }
    }
    else {
        $VersionText.Text = 'YubiEnroll hittades inte'
        $MainTabs.SelectedIndex = 4
    }
    if ($SelfTest) {
        $sampleRows = @(ConvertFrom-YubiTable "ID    Username    Email`r`n----  ----------  ----------------`r`n42    test.user   test@example.com")
        if ($sampleRows.Count -ne 1 -or $sampleRows[0].ID -ne '42') { throw 'Självtestet kunde inte tolka CLI-tabeller.' }
        $emptyProfileRows = @(ConvertFrom-YubiTable "Name  Minimum PIN length  Require always UV  Require EA  Force PIN change  Factory reset  Random PIN  Random PIN length`r`n----  ------------------  -----------------  ----------  ----------------  -------------  ----------  -----------------")
        if ($emptyProfileRows.Count -ne 0) { throw 'Självtestet behandlade en tabellrubrik som en profil.' }
        $profileRowsWithoutSeparator = @(ConvertFrom-YubiTable "Name  Minimum PIN length  Require always UV  Require EA  Force PIN change  Factory reset  Random PIN  Random PIN length`r`nNCSC  6                   False              False       True              False          True        8")
        if ($profileRowsWithoutSeparator.Count -ne 1 -or $profileRowsWithoutSeparator[0].Name -ne 'NCSC' -or $profileRowsWithoutSeparator[0].'Random PIN length' -ne '8') { throw 'Självtestet kunde inte dela upp en profilrad i kolumner.' }
        Set-ComboByText $EnrollRandomPinCombo 'På'
        if ((Get-ComboText $EnrollRandomPinCombo) -ne 'På') { throw 'Självtestet kunde inte välja ett trelägesvärde.' }
        Write-Output 'YubiEnroll GUI self-test: OK'
        $window.Close()
        return
    }
    $StatusButton.RaiseEvent([System.Windows.RoutedEventArgs]::new([System.Windows.Controls.Button]::ClickEvent))
})

[void]$window.ShowDialog()
