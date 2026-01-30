# DBeaver Tips and Tricks

Useful configurations and fixes for DBeaver database management tool.

---

## Increasing Toolbar Icon Size

If the toolbar icons are too small (common on high-DPI displays), you can scale them up.

**Reference:** [GitHub Issue #20704](https://github.com/dbeaver/dbeaver/issues/20704#issuecomment-1700730969)

### Steps:

1. Locate the `dbeaver.ini` file in the DBeaver installation directory
2. Add these parameters at the **end of the file**:

```ini
-Dswt.enable.autoScale=true
-Dswt.autoScale=200
-Dswt.autoScale.method=nearest
```

3. Save the file and restart DBeaver

### Adjusting the Scale

You can change the icon size by modifying the value of `-Dswt.autoScale`:

| Value | Result |
|-------|--------|
| `100` | Normal size (100%) |
| `150` | 1.5× bigger |
| `200` | 2× bigger |
| `300` | 3× bigger |

---

## Fix: Invalid TimeZone Error

### Error Message

```
FATAL: invalid value for parameter "TimeZone": "Asia/Saigon"
```

This error occurs when connecting to PostgreSQL because `Asia/Saigon` is not a valid timezone identifier.

### Solution

Add the following line to `dbeaver.ini`, **after** the `-vmargs` line:

```ini
-Duser.timezone=Asia/Ho_Chi_Minh
```

This sets the correct timezone (`Asia/Ho_Chi_Minh` is the valid IANA timezone for Vietnam) and resolves the PostgreSQL connection error.

### Example dbeaver.ini structure

```ini
-startup
plugins/org.eclipse.equinox.launcher_1.x.x.jar
...
-vmargs
-Duser.timezone=Asia/Ho_Chi_Minh
-Dswt.enable.autoScale=true
-Dswt.autoScale=200
-Dswt.autoScale.method=nearest
```

---

## 📚 References

- [DBeaver Official Documentation](https://dbeaver.com/docs/)
- [DBeaver GitHub Issues](https://github.com/dbeaver/dbeaver/issues)
