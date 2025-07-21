from django.shortcuts import render


def home(request):
    """
    View function for the homepage
    """
    return render(request, 'rbennettio/home.html')
