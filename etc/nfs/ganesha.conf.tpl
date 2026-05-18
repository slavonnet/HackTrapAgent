NFS_CORE_PARAM {
  Protocols = 4;
}

EXPORT_DEFAULTS {
  Access_Type = NONE;
}

EXPORT {
  Export_Id = 1;
  Path = ${NFS_EXPORT_PATH};
  Pseudo = ${NFS_PSEUDO_PATH};
  Access_Type = RW;
  Squash = root_squash;
  SecType = sys;
  Protocols = 4;
  Transports = TCP;
  CLIENT {
    Clients = ${NFS_ALLOWED_CLIENTS};
    Access_Type = RW;
  }
  FSAL {
    Name = VFS;
  }
}

LOG {
  Default_Log_Level = ${NFS_LOG_LEVEL};
  Facility {
    name = FILE;
    destination = "/var/log/nfs/ganesha.log";
    enable = active;
  }
}
