package com.example.plugin;

import org.bukkit.plugin.java.JavaPlugin;

// Rename this class (and the file, and the package folder, and "main:" in
// plugin.yml) to match whatever the plugin is actually called.
public class ExamplePlugin extends JavaPlugin {

    @Override
    public void onEnable() {
        getLogger().info(getName() + " enabled.");
        // Register commands/listeners here, e.g.:
        // getServer().getPluginManager().registerEvents(new MyListener(), this);
    }

    @Override
    public void onDisable() {
        getLogger().info(getName() + " disabled.");
    }
}
