from django.db import models


class DummyModel(models.Model):
    name = models.CharField(max_length=20)

    def __str__(self):
        return self.name


class ManagementCommand(models.Model):
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True)
    last_run = models.DateTimeField(null=True, blank=True)
    success = models.BooleanField(null=True, blank=True)
    output = models.TextField(blank=True)
    
    def __str__(self):
        return self.name
        
    class Meta:
        verbose_name = "Management Command"
        verbose_name_plural = "Management Commands"
